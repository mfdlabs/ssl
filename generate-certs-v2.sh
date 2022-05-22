#!/bin/bash

# Constants
NO_ROOT_ON_INSERT_TO_CA_STORE="This requires you to run as root if you want to insert the root certificate into the current machine's root certificate authority. If you don't want to insert it into the root certificate authority, please set the sixth parameter of this command to \"NO\"."
CERT_BIN=$PWD/bin
ROOT_CA_PREFIX=$CERT_BIN/root-ca-
CA_PREFIX=$CERT_BIN/ca-
ALL_AUTHORITHY_PREFIX=$CERT_BIN/
CA_CERTS_STORE=/usr/local/share/ca-certificates/

# Create cert bin directory if it doesn't exist
if [ ! -d $CERT_BIN ]; then
	mkdir $CERT_BIN
fi

if [ $# -eq 0 ]; then
    echo "Usage: $0 CERT_NAME CERT_PASSWORD PFX_PASSWORD CHAIN_NAME CHAIN_PASSWORD [IS_CHAIN_ROOT_CA=YES] [DO_NOT_GENERATE_DHPARAM=NO] [KEEP_CERTIFICATE_REQUEST_FILE=NO] [EXPIRATION_IN_DAYS=4096] [KEY_LENGTH=2048] [EXTENSION_FILE_EXTENSION=.conf]"
    exit 1
fi

CERT_NAME=$1
CERT_PASSWORD=$2
PFX_PASSWORD=$3
CHAIN_NAME=$4
CHAIN_PASSWORD=$5
IS_CHAIN_ROOT_CA=$6
DO_NOT_GENERATE_DHPARAM=$7
KEEP_CERTIFICATE_REQUEST_FILE=$8
EXPIRATION_IN_DAYS=$9
KEY_LENGTH=${10}
EXTENSION_FILE_EXTENSION=${11}

if [ -z "$CERT_NAME" ] || [ ${#CERT_NAME} -lt 1 ] ; 
then
	echo "Missing parameter CERT_NAME or it was less than 1 characters in length, for intermediate certificate name, this is required."
	exit 1
fi

if [ -z "$CERT_PASSWORD" ] || [ ${#CERT_PASSWORD} -lt 4 ] ;
then
	echo "Missing parameter CERT_PASSWORD or it was less than 4 characters in length, for intermediate certificate password, this is required."
	exit 1
fi

if [ -z "$PFX_PASSWORD" ] || [ ${#PFX_PASSWORD} -lt 4 ] ;
then
	echo "Missing parameter PFX_PASSWORD or it was less than 4 characters in length, for intermediate certificate pfx password, this is required."
	exit 1
fi

if [ -z "$CHAIN_NAME" ] || [ ${#CHAIN_NAME} -lt 1 ] ; 
then
	echo "Missing parameter CHAIN_NAME or it was less than 1 characters in length, for root certificate name, this is required."
	exit 1
fi

if [ -z "$CHAIN_PASSWORD" ] || [ ${#CHAIN_PASSWORD} -lt 4 ] ;
then
	echo "Missing parameter CHAIN_PASSWORD or it was less than 4 characters in length, for root certificate password, this is required."
	exit 1
fi

if [ -z "$DO_NOT_GENERATE_DHPARAM" ] ;
then
	DO_NOT_GENERATE_DHPARAM=NO
fi

if [ -z "$EXTENSION_FILE_EXTENSION"	]; then
	EXTENSION_FILE_EXTENSION=".conf"
fi

if [ -z "$KEY_LENGTH" ]; then
	KEY_LENGTH=2048
fi

if [ -z "$(echo $KEY_LENGTH | sed -n '/^[0-9]\+$/p')" ] ;
then
	echo "KEY_LENGTH must be a number."
	exit 1
fi

# If the key length is not 1024, 2048, or 4096, then exit
if [ $KEY_LENGTH -ne 1024 ] && [ $KEY_LENGTH -ne 2048 ] && [ $KEY_LENGTH -ne 4096 ]; then
	echo "KEY_LENGTH must be 1024, 2048, or 4096."
	exit 1
fi

if [ -z "$EXPIRATION_IN_DAYS" ] ;
then
	EXPIRATION_IN_DAYS=4086
fi

# If expiration in days is not a number, exit
if [ -z "$(echo $EXPIRATION_IN_DAYS | sed -n '/^[0-9]\+$/p')" ] ;
then
	echo "EXPIRATION_IN_DAYS must be a number."
	exit 1
fi

if [ $EXPIRATION_IN_DAYS -lt 0 ] ;
then
	echo "EXPIRATION_IN_DAYS must be greater than or equal to 0."
	exit 1
fi

if [ -z "$KEEP_CERTIFICATE_REQUEST_FILE" ] ;
then
	KEEP_CERTIFICATE_REQUEST_FILE=NO
fi

if [ -z "$IS_CHAIN_ROOT_CA" ] ;
then
	IS_CHAIN_ROOT_CA=YES
fi

if [ "$IS_CHAIN_ROOT_CA" = "NO" ] ;
then
	ROOT_CA_PREFIX=$CA_PREFIX
fi

ALL_AUTHORITHY_NAME=$ALL_AUTHORITHY_PREFIX$CERT_NAME
CONFIG_FILE_NAME=$ALL_AUTHORITHY_NAME$EXTENSION_FILE_EXTENSION
CREDENTIALS_FILE_NAME=$ALL_AUTHORITHY_NAME.credentials.txt

# Check if config file does not exist
if [ ! -f $CONFIG_FILE_NAME ] ;
then
	echo "Config file $CONFIG_FILE_NAME does not exist."
	exit 1
fi

ROOT_CHAIN_NAME=$ROOT_CA_PREFIX$CHAIN_NAME

printf "# Root Directory: %s\n# CA Name: %s\n# Intermediate Cert Name: %s\nCA: %s\nIntermediate Cert: %s\nIntermediate Cert PFX: %s\n" $PWD $ROOT_CHAIN_NAME $ALL_AUTHORITHY_NAME $CHAIN_PASSWORD $CERT_PASSWORD $PFX_PASSWORD
printf "# Root Directory: %s\n# CA Name: %s\n# Intermediate Cert Name: %s\nCA: %s\nIntermediate Cert: %s\nIntermediate Cert PFX: %s\n" $PWD $ROOT_CHAIN_NAME $ALL_AUTHORITHY_NAME $CHAIN_PASSWORD $CERT_PASSWORD $PFX_PASSWORD > $CREDENTIALS_FILE_NAME

# Top header constants
KEY_FILE_NAME=$ALL_AUTHORITHY_NAME.key
UNENCRYPTED_KEY_FILE_NAME=$ALL_AUTHORITHY_NAME.unencrypted.key
CSR_FILE_NAME=$ALL_AUTHORITHY_NAME.csr
CA_FILE_NAME=$ROOT_CHAIN_NAME.crt
CA_KEY_FILE_NAME=$ROOT_CHAIN_NAME.key
INTERMEDIATE_CERT_FILE_NAME=$ALL_AUTHORITHY_NAME.crt
INTERMEDIATE_CERT_PFX_FILE_NAME=$ALL_AUTHORITHY_NAME.pfx
INTERMEDIATE_PEM_CERT_FILE_NAME=$ALL_AUTHORITHY_NAME.pem
INTERMEDIATECERT_DH_PARAM_FILE_NAME=$ALL_AUTHORITHY_NAME.dhparam.pem
PASSWORD_FILE_NAME=$ALL_AUTHORITHY_NAME.password.txt

# Certificate's password
printf "%s" $CERT_PASSWORD > $PASSWORD_FILE_NAME

# private key
openssl genrsa -des3 -passout pass:$CERT_PASSWORD -out $KEY_FILE_NAME $KEY_LENGTH

# get unencrypted private key
openssl rsa -in $KEY_FILE_NAME -out $UNENCRYPTED_KEY_FILE_NAME -passin pass:$CERT_PASSWORD

# generate certificate signing request
openssl req -new -key $KEY_FILE_NAME -passin pass:$CERT_PASSWORD -out $CSR_FILE_NAME -config $CONFIG_FILE_NAME

# generate certificate
openssl x509 -req -days $EXPIRATION_IN_DAYS -in $CSR_FILE_NAME -CA $CA_FILE_NAME -CAkey $CA_KEY_FILE_NAME -CAcreateserial -passin pass:$CHAIN_PASSWORD -out $INTERMEDIATE_CERT_FILE_NAME -sha256 -extfile $CONFIG_FILE_NAME -extensions config_extensions

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
