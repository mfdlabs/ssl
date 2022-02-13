#!/bin/bash

# Constants
NO_ROOT_ON_INSERT_TO_CA_STORE="This requires you to run as root if you want to insert the root certificate into the current machine's root certificate authority. If you don't want to insert it into the root certificate authority, please set the sixth parameter of this command to \"NO\"."
CERT_BIN=$PWD/bin
ROOT_CA_PREFIX=$CERT_BIN/mfdlabs-root-ca-
CA_PREFIX=$CERT_BIN/mfdlabs-ca-
CA_CERTS_STORE=/usr/local/share/ca-certificates/

# Create cert bin directory if it doesn't exist
if [ ! -d $CERT_BIN ]; then
	mkdir $CERT_BIN
fi

if [ $# -eq 0 ]; then
    echo "Usage: $PWD/generate-intermediate-ca.sh IS_ROOT_CA CA_CHAIN_NAME CA_CHAIN_PASSWORD CA_NAME CA_PASSWORD PFX_PASSWORD INSERT_CA_INTO_TRUSTED_CERTS DO_NOT_GENERATE_DHPARAM KEEP_CERTIFICATE_REQUEST_FILE"
    exit 1
fi


# This only refers to if the last certificate in the chain is a root certificate, so it can get the correct CA_PREFIX
IS_ROOT_CA=$1
CA_CHAIN_NAME=$2
CA_CHAIN_PASSWORD=$3
CA_NAME=$4
CA_PASSWORD=$5
PFX_PASSWORD=$6
INSERT_CA_INTO_TRUSTED_CERTS=$7
DO_NOT_GENERATE_DHPARAM=$8
KEEP_CERTIFICATE_REQUEST_FILE=$9

if [ -z "$KEEP_CERTIFICATE_REQUEST_FILE" ] ;
then
	KEEP_CERTIFICATE_REQUEST_FILE=NO
fi

if [ -z "$IS_ROOT_CA" ] ;
then
	IS_ROOT_CA=YES
fi

if [ "$IS_ROOT_CA" = "NO" ] ;
then
    ROOT_CA_PREFIX=$CA_PREFIX
fi

if [ -z "$INSERT_CA_INTO_TRUSTED_CERTS" ] ;
then
	INSERT_CA_INTO_TRUSTED_CERTS=NO
fi

if [ "$EUID" -ne 0 ] && [ "$INSERT_CA_INTO_TRUSTED_CERTS" = "YES" ] ; 
then 
  echo $NO_ROOT_ON_INSERT_TO_CA_STORE
  exit 1
fi


if [ -z "$CA_CHAIN_NAME" ] || [ ${#CA_CHAIN_NAME} -le 1 ] ; 
then
	echo "Missing parameter CA_CHAIN_NAME or it was less than 3 or equal to characters in length, for root certificate name, this is required."
	exit 1
fi

if [ -z "$CA_CHAIN_PASSWORD" ] || [ ${#CA_CHAIN_PASSWORD} -le 4 ] ;
then
	echo "Missing parameter CA_CHAIN_PASSWORD or it was less than 4 equal to characters in length, for root certificate password, this is required."
	exit 1
fi

if [ -z "$CA_NAME" ] || [ ${#CA_NAME} -le 1 ] ; 
then
	echo "Missing parameter CA_NAME or it was less than 1 or equal to characters in length, for intermediate certificate name, this is required."
	exit 1
fi

if [ -z "$CA_PASSWORD" ] || [ ${#CA_PASSWORD} -le 4 ] ;
then
	echo "Missing parameter CA_PASSWORD or it was less than 4 equal to characters in length, for intermediate certificate password, this is required."
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


CA_CERT_FQN=$CA_PREFIX$CA_NAME
CA_CONFIG_FILE=$CA_CERT_FQN.conf

# Check if the config file does not exist
if [ ! -f $CA_CONFIG_FILE ] ;
then
	echo "The config file $CA_CONFIG_FILE does not exist, please create it first."
	exit 1
fi

CA_CHAIN_FQN=$ROOT_CA_PREFIX$CA_CHAIN_NAME
CA_CERT_CREDENTIALS=$CA_CERT_FQN.credentials.txt
CA_KEY_FILE_NAME=$CA_CERT_FQN.key
UNENCRYPTED_CA_KEY_FILE_NAME=$CA_CERT_FQN.unencrypted.key
CA_CERT_FILE_NAME=$CA_CERT_FQN.crt
CA_CHAIN_FILE_NAME=$CA_CHAIN_FQN.crt
CA_CHAIN_KEY_FILE_NAME=$CA_CHAIN_FQN.key
CA_CERTIFICATE_REQUEST_FILE_NAME=$CA_CERT_FQN.csr
CA_CERT_PFX_FILE_NAME=$CA_CERT_FQN.pfx
CA_CERT_PEM_FILE_NAME=$CA_CERT_FQN.pem
CA_CERT_PASSWORD_FILE_NAME=$CA_CERT_FQN.password.txt
CA_CERT_STORE_OUTPUT_FILE_NAME=$CA_CERTS_STORE$CA_CERT_FILE_NAME

printf "# Command: %s/generate-intermediate-ca.sh %s %s %s %s %s %s %s %s %s\n# Root Directory: %s\n# CA Name: %s\n# Intermediate CA Name: %s\nRootCA: %s\nIntermediate CA: %s\nIntermediate CA PFX: %s\n" $PWD $IS_ROOT_CA $CA_CHAIN_NAME $CA_CHAIN_PASSWORD $CA_NAME $CA_PASSWORD $PFX_PASSWORD $INSERT_CA_INTO_TRUSTED_CERTS $DO_NOT_GENERATE_DHPARAM $KEEP_CERTIFICATE_REQUEST_FILE $PWD $CA_CHAIN_FQN $CA_CERT_FQN $CA_CHAIN_PASSWORD $CA_PASSWORD $PFX_PASSWORD
printf "# Command: %s/generate-intermediate-ca.sh %s %s %s %s %s %s %s %s %s\n# Root Directory: %s\n# CA Name: %s\n# Intermediate CA Name: %s\nRootCA: %s\nIntermediate CA: %s\nIntermediate CA PFX: %s\n" $PWD $IS_ROOT_CA $CA_CHAIN_NAME $CA_CHAIN_PASSWORD $CA_NAME $CA_PASSWORD $PFX_PASSWORD $INSERT_CA_INTO_TRUSTED_CERTS $DO_NOT_GENERATE_DHPARAM $KEEP_CERTIFICATE_REQUEST_FILE $PWD $CA_CHAIN_FQN $CA_CERT_FQN $CA_CHAIN_PASSWORD $CA_PASSWORD $PFX_PASSWORD > $CA_CERT_FQN.credentials.txt

# Certificate's password
printf "%s" $CA_PASSWORD > $CA_CERT_PASSWORD_FILE_NAME

# private key
openssl genrsa -des3 -passout pass:$CA_PASSWORD -out $CA_KEY_FILE_NAME 2048

# get unencrypted private key
openssl rsa -in $CA_KEY_FILE_NAME -out $UNENCRYPTED_CA_KEY_FILE_NAME -passin pass:$CA_PASSWORD

# generate certificate signing request
openssl req -new -key $CA_KEY_FILE_NAME -passin pass:$CA_PASSWORD -out $CA_CERTIFICATE_REQUEST_FILE_NAME -config $CA_CONFIG_FILE

# generate certificate
openssl x509 -req -days 3500 -in $CA_CERTIFICATE_REQUEST_FILE_NAME -CA $CA_CHAIN_FILE_NAME -CAkey $CA_CHAIN_KEY_FILE_NAME -CAcreateserial -passin pass:$CA_CHAIN_PASSWORD -out $CA_CERT_FILE_NAME -sha256 -extfile $CA_CONFIG_FILE -extensions config_extensions

# generate pfx
openssl pkcs12 -export -passin pass:$CA_PASSWORD -password pass:$PFX_PASSWORD -out $CA_CERT_PFX_FILE_NAME -inkey $CA_KEY_FILE_NAME -in $CA_CERT_FILE_NAME -CAfile $CA_CHAIN_FILE_NAME

# extract pem from pfx
openssl pkcs12 -password pass:$PFX_PASSWORD -in $CA_CERT_PFX_FILE_NAME -out $CA_CERT_PEM_FILE_NAME -nodes

if [ "$INSERT_CA_INTO_TRUSTED_CERTS" = "YES" ] ;
then
	cp $CA_CERT_FILE_NAME $CA_CERT_STORE_OUTPUT_FILE_NAME --force
fi

# Check if we aren't keeping the csr file

if [ "$KEEP_CERTIFICATE_REQUEST_FILE" = "NO" ] ;
then
	rm $CA_CERTIFICATE_REQUEST_FILE_NAME --force --verbose
fi

if [ "$DO_NOT_GENERATE_DHPARAM" = "NO" ] ;
then
	# generate dhparam
	openssl dhparam -in $CA_CERT_FILE_NAME -out $CA_CERT_FQN-dhparam.pem 2048
fi
