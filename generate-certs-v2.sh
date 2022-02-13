#!/bin/bash

# Constants
NO_ROOT_ON_INSERT_TO_CA_STORE="This requires you to run as root if you want to insert the root certificate into the current machine's root certificate authority. If you don't want to insert it into the root certificate authority, please set the sixth parameter of this command to \"NO\"."
CERT_BIN=$PWD/bin
ROOT_CA_PREFIX=$CERT_BIN/mfdlabs-root-ca-
CA_PREFIX=$CERT_BIN/mfdlabs-ca-
ALL_AUTHORITHY_PREFIX=$CERT_BIN/mfdlabs-all-authority-
CA_CERTS_STORE=/usr/local/share/ca-certificates/

# Create cert bin directory if it doesn't exist
if [ ! -d $CERT_BIN ]; then
	mkdir $CERT_BIN
fi

if [ $# -eq 0 ]; then
    echo "Usage: $PWD/generate-certs-v2.sh IS_ROOT_CA CA_NAME CA_PASSWORD CERT_NAME CERT_PASSWORD PFX_PASSWORD DO_NOT_GENERATE_DHPARAM KEEP_CERTIFICATE_REQUEST_FILE"
    exit 1
fi

IS_ROOT_CA=$1
CA_NAME=$2
CA_PASSWORD=$3
CERT_NAME=$4
CERT_PASSWORD=$5
PFX_PASSWORD=$6
DO_NOT_GENERATE_DHPARAM=$7
KEEP_CERTIFICATE_REQUEST_FILE=$8

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


if [ -z "$CA_NAME" ] || [ ${#CA_NAME} -le 1 ] ; 
then
	echo "Missing parameter CA_NAME or it was less than 3 or equal to characters in length, for root certificate name, this is required."
	exit 1
fi

if [ -z "$CA_PASSWORD" ] || [ ${#CA_PASSWORD} -le 4 ] ;
then
	echo "Missing parameter CA_PASSWORD or it was less than 4 equal to characters in length, for root certificate password, this is required."
	exit 1
fi

if [ -z "$CERT_NAME" ] || [ ${#CERT_NAME} -le 1 ] ; 
then
	echo "Missing parameter CERT_NAME or it was less than 1 or equal to characters in length, for intermediate certificate name, this is required."
	exit 1
fi

if [ -z "$CERT_PASSWORD" ] || [ ${#CERT_PASSWORD} -le 4 ] ;
then
	echo "Missing parameter CERT_PASSWORD or it was less than 4 equal to characters in length, for intermediate certificate password, this is required."
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

ALL_AUTHORITHY_NAME=$ALL_AUTHORITHY_PREFIX$CERT_NAME
CONFIG_FILE_NAME=$ALL_AUTHORITHY_NAME.conf
CREDENTIALS_FILE_NAME=$ALL_AUTHORITHY_NAME.credentials.txt

# Check if config file does not exist
if [ ! -f $CONFIG_FILE_NAME ] ;
then
	echo "Config file $CONFIG_FILE_NAME does not exist."
	exit 1
fi

ROOT_CA_NAME=$ROOT_CA_PREFIX$CA_NAME

printf "# Command: %s/generate-certs-v2.sh %s %s %s %s %s %s %s %s\n# Root Directory: %s\n# CA Name: %s\n# Intermediate Cert Name: %s\nCA: %s\nIntermediate Cert: %s\nIntermediate Cert PFX: %s\n" $PWD $IS_ROOT_CA $CA_NAME $CA_PASSWORD $CERT_NAME $CERT_PASSWORD $PFX_PASSWORD $DO_NOT_GENERATE_DHPARAM $KEEP_CERTIFICATE_REQUEST_FILE $PWD $ROOT_CA_NAME $ALL_AUTHORITHY_NAME $CA_PASSWORD $CERT_PASSWORD $PFX_PASSWORD
printf "# Command: %s/generate-certs-v2.sh %s %s %s %s %s %s %s %s\n# Root Directory: %s\n# CA Name: %s\n# Intermediate Cert Name: %s\nCA: %s\nIntermediate Cert: %s\nIntermediate Cert PFX: %s\n" $PWD $IS_ROOT_CA $CA_NAME $CA_PASSWORD $CERT_NAME $CERT_PASSWORD $PFX_PASSWORD $DO_NOT_GENERATE_DHPARAM $KEEP_CERTIFICATE_REQUEST_FILE $PWD $ROOT_CA_NAME $ALL_AUTHORITHY_NAME $CA_PASSWORD $CERT_PASSWORD $PFX_PASSWORD > $CREDENTIALS_FILE_NAME

# Top header constants
KEY_FILE_NAME=$ALL_AUTHORITHY_NAME.key
UNENCRYPTED_KEY_FILE_NAME=$ALL_AUTHORITHY_NAME.unencrypted.key
CSR_FILE_NAME=$ALL_AUTHORITHY_NAME.csr
CA_FILE_NAME=$ROOT_CA_NAME.crt
CA_KEY_FILE_NAME=$ROOT_CA_NAME.key
INTERMEDIATE_CERT_FILE_NAME=$ALL_AUTHORITHY_NAME.crt
INTERMEDIATE_CERT_PFX_FILE_NAME=$ALL_AUTHORITHY_NAME.pfx
INTERMEDIATE_PEM_CERT_FILE_NAME=$ALL_AUTHORITHY_NAME.pem
INTERMEDIATECERT_DH_PARAM_FILE_NAME=$ALL_AUTHORITHY_NAME.dhparam.pem
PASSWORD_FILE_NAME=$ALL_AUTHORITHY_NAME.password.txt

# Certificate's password
printf "%s" $CERT_PASSWORD > $PASSWORD_FILE_NAME

# private key
openssl genrsa -des3 -passout pass:$CERT_PASSWORD -out $KEY_FILE_NAME 2048

# get unencrypted private key
openssl rsa -in $KEY_FILE_NAME -out $UNENCRYPTED_KEY_FILE_NAME -passin pass:$CERT_PASSWORD

# generate certificate signing request
openssl req -new -key $KEY_FILE_NAME -passin pass:$CERT_PASSWORD -out $CSR_FILE_NAME -config $CONFIG_FILE_NAME

# generate certificate
openssl x509 -req -days 3500 -in $CSR_FILE_NAME -CA $CA_FILE_NAME -CAkey $CA_KEY_FILE_NAME -CAcreateserial -passin pass:$CA_PASSWORD -out $INTERMEDIATE_CERT_FILE_NAME -sha256 -extfile $CONFIG_FILE_NAME -extensions config_extensions

# generate pfx
openssl pkcs12 -export -passin pass:$CERT_PASSWORD -password pass:$PFX_PASSWORD -out $INTERMEDIATE_CERT_PFX_FILE_NAME -inkey $KEY_FILE_NAME -in $INTERMEDIATE_CERT_FILE_NAME -CAfile $CA_FILE_NAME

# extract pem from pfx
openssl pkcs12 -password pass:$PFX_PASSWORD -in $INTERMEDIATE_CERT_PFX_FILE_NAME -out $INTERMEDIATE_PEM_CERT_FILE_NAME -nodes

if [ "$KEEP_CERTIFICATE_REQUEST_FILE" = "NO" ] ;
then
	# delete certificate request file
	rm $CSR_FILE_NAME --force --verbose
fi

if [ "$DO_NOT_GENERATE_DHPARAM" = "NO" ] ;
then
	# generate dhparam
	openssl dhparam -in $INTERMEDIATE_CERT_FILE_NAME -out $INTERMEDIATECERT_DH_PARAM_FILE_NAME 2048
fi
