#!/bin/bash

# Generates a root CA certificate and key.
# Use config extensions file if you want to specify specific attributes for the certificate like policy, key usage, extended key usage, etc.

# Constants
NO_ROOT_ON_INSERT_TO_CA_STORE="This requires you to run as root if you want to insert the root certificate into the current machine's root certificate authority. If you don't want to insert it into the root certificate authority, please set the fourth parameter of this command to \"NO\"."
CERT_BIN=$PWD/bin
ROOT_CA_PREFIX=$CERT_BIN/mfdlabs-root-ca-
CA_CERTS_STORE=/usr/local/share/ca-certificates/

# Create cert bin directory if it doesn't exist
if [ ! -d $CERT_BIN ]; then
	mkdir $CERT_BIN
fi

# Variables

if [ $# -eq 0 ]; then
    echo "Usage: $PWD/generate-certs-v2.sh ROOT_CA_NAME ROOT_CA_PASSWORD PFX_PASSWORD INSERT_ROOT_CA_INTO_TRUSTED_CERTS DO_NOT_GENERATE_DHPARAM HAS_EXTENSION_FILE"
    exit 1
fi

ROOT_CA_NAME=$1
ROOT_CA_PASSWORD=$2
PFX_PASSWORD=$3
INSERT_ROOT_CA_INTO_TRUSTED_CERTS=$4
DO_NOT_GENERATE_DHPARAM=$5
HAS_EXTENSION_FILE=$6

if [ -z "$INSERT_ROOT_CA_INTO_TRUSTED_CERTS" ] ;
then
	INSERT_ROOT_CA_INTO_TRUSTED_CERTS=NO
fi

if [ -z "$HAS_EXTENSION_FILE" ] ;
then
	HAS_EXTENSION_FILE=NO
fi

if [ "$EUID" -ne 0 ] && [ "$INSERT_ROOT_CA_INTO_TRUSTED_CERTS" = "YES" ] ; 
then 
  echo $NO_ROOT_ON_INSERT_TO_CA_STORE
  exit 1
fi


if [ -z "$ROOT_CA_NAME" ] || [ ${#ROOT_CA_NAME} -le 1 ] ; 
then
	echo "Missing parameter ROOT_CA_NAME or it was less than 1 or equal to characters in length, for root certificate name, this is required."
	exit 1
fi

if [ -z "$ROOT_CA_PASSWORD" ] || [ ${#ROOT_CA_PASSWORD} -le 4 ] ;
then
	echo "Missing parameter ROOT_CA_PASSWORD or it was less than 4 equal to characters in length, for root certificate password, this is required."
	exit 1
fi

if [ -z "$PFX_PASSWORD" ] || [ ${#PFX_PASSWORD} -le 4 ] ;
then
	echo "Missing parameter PFX_PASSWORD or it was less than 4 equal to characters in length, for intermediate certificate pfx password, this is required."
	exit 1
fi

if [ -z "$DO_NOT_GENERATE_DHPARAM" ] ;
then
	DO_NOT_GENERATE_DHPARAM=NO
fi

CA_NAME=$ROOT_CA_PREFIX$ROOT_CA_NAME
CREDENTIALS_FILE_NAME=$CA_NAME.credentials.txt
CA_PASSWORD_FILE_NAME=$CA_NAME.password.txt

printf "# Command: %s/generate-root-ca.sh %s %s %s %s %s %s\n# Root Directory: %s\n# RootCA Name: %s\nRootCA: %s\nRootCA PFX: %s\n" $PWD $ROOT_CA_NAME $ROOT_CA_PASSWORD $PFX_PASSWORD $INSERT_ROOT_CA_INTO_TRUSTED_CERTS $HAS_EXTENSION_FILE $DO_NOT_GENERATE_DHPARAM $PWD $CA_NAME $ROOT_CA_PASSWORD $PFX_PASSWORD
printf "# Command: %s/generate-root-ca.sh %s %s %s %s %s %s\n# Root Directory: %s\n# RootCA Name: %s\nRootCA: %s\nRootCA PFX: %s\n" $PWD $ROOT_CA_NAME $ROOT_CA_PASSWORD $PFX_PASSWORD $INSERT_ROOT_CA_INTO_TRUSTED_CERTS $HAS_EXTENSION_FILE $DO_NOT_GENERATE_DHPARAM $PWD $CA_NAME $ROOT_CA_PASSWORD $PFX_PASSWORD > $CREDENTIALS_FILE_NAME

CA_KEY_FILE_NAME=$CA_NAME.key
UNENCRYPTED_CA_KEY_FILE_NAME=$CA_NAME.unecrypted.key
CA_CERT_NAME=$CA_NAME.crt
CA_PFX_CERT_NAME=$CA_NAME.pfx
CA_PEM_CERT_NAME=$CA_NAME.pem
CA_CERT_STORE_OUTPUT_FILE_NAME=$CA_CERTS_STORE$CA_CERT_NAME
CA_CERT_DH_PARAM_FILE_NAME=$CA_NAME.dhparam.pem

# Root CA's password
printf "%s" $ROOT_CA_PASSWORD > $CA_PASSWORD_FILE_NAME

# Generate private key
openssl genrsa -des3 -passout pass:$ROOT_CA_PASSWORD -out $CA_KEY_FILE_NAME 2048

# Generate unecrypted private key
openssl rsa -in $CA_KEY_FILE_NAME -out $UNENCRYPTED_CA_KEY_FILE_NAME -passin pass:$ROOT_CA_PASSWORD

# Check if we are generating a root ca with an extension file
if [ "$HAS_EXTENSION_FILE" = "YES" ] ;
then
	EXTENSION_FILE_NAME=$CA_NAME.conf

	# Check if the extension file exists
	if [ -f $EXTENSION_FILE_NAME ] ;
	then
		# Generate the root ca certificate reading the specified extension file
		openssl req -x509 -new -nodes -key $CA_KEY_FILE_NAME -sha256 -days 4086 -extensions config_extensions -config $EXTENSION_FILE_NAME -out $CA_CERT_NAME -passin pass:$ROOT_CA_PASSWORD
	else
		echo "Extension file $EXTENSION_FILE_NAME does not exist."
		exit 1
	fi
else
	# Generate root ca certificate
	openssl req -x509 -new -nodes -key $CA_KEY_FILE_NAME -sha256 -days 4086 -passin pass:$ROOT_CA_PASSWORD -out $CA_CERT_NAME
fi

# Generate pfx
openssl pkcs12 -export -passin pass:$ROOT_CA_PASSWORD -password pass:$PFX_PASSWORD -out $CA_PFX_CERT_NAME -inkey $CA_KEY_FILE_NAME -in $CA_CERT_NAME

# Extract pem from pfx
openssl pkcs12 -password pass:$PFX_PASSWORD -in $CA_PFX_CERT_NAME -out $CA_PEM_CERT_NAME -nodes

if [ "$INSERT_ROOT_CA_INTO_TRUSTED_CERTS" = "YES" ] ;
then
	# Insert root CA into trusted certs
	cp $CA_CERT_NAME $CA_CERT_STORE_OUTPUT_FILE_NAME --force
fi

if [ "$DO_NOT_GENERATE_DHPARAM" = "NO" ] ;
then
	# Generate DH parameters
	openssl dhparam -in $CA_CERT_NAME -out $CA_CERT_DH_PARAM_FILE_NAME 2048
fi