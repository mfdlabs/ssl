#!/bin/bash

# Constants
NO_ROOT_ON_INSERT_TO_CA_STORE="This requires you to run as root if you want to insert the root certificate into the current machine's root certificate authority. If you don't want to insert it into the root certificate authority, please set the sixth parameter of this command to \"NO\"."
CERT_BIN=$PWD/bin
ROOT_CA_PREFIX=$CERT_BIN/root-ca-
CA_PREFIX=$CERT_BIN/ca-
CA_CERTS_STORE=/usr/local/share/ca-certificates/

# Create cert bin directory if it doesn't exist
if [ ! -d $CERT_BIN ]; then
	mkdir $CERT_BIN
fi

if [ $# -eq 0 ]; then
    echo "Usage: $0 CA_NAME CA_PASSWORD PFX_PASSWORD CHAIN_NAME CHAIN_PASSWORD [IS_CHAIN_ROOT_CA=YES] [INSERT_CA_INTO_TRUSTED_CERTS=NO] [DO_NOT_GENERATE_DHPARAM=NO] [KEEP_CERTIFICATE_REQUEST_FILE=NO] [EXPIRATION_IN_DAYS=4096] [KEY_LENGTH=2048] [EXTENSION_FILE_EXTENSION=.conf]"
    exit 1
fi

CA_NAME=$1
CA_PASSWORD=$2
PFX_PASSWORD=$3
CHAIN_NAME=$4
CHAIN_PASSWORD=$5
IS_CHAIN_ROOT_CA=$6
INSERT_CA_INTO_TRUSTED_CERTS=$7
DO_NOT_GENERATE_DHPARAM=$8
KEEP_CERTIFICATE_REQUEST_FILE=$9
EXPIRATION_IN_DAYS=${10}
KEY_LENGTH=${11}
EXTENSION_FILE_EXTENSION=${12}

# If the password starts with an @, then it is a file containing the password
if [ "${CA_PASSWORD:0:1}" == "@" ]; then
	CERT_PASSWORD=$(cat ${CERT_PASSWORD:1})
fi

if [ "${PFX_PASSWORD:0:1}" == "@" ]; then
	PFX_PASSWORD=$(cat ${PFX_PASSWORD:1})
fi

if [ "${CHAIN_PASSWORD:0:1}" == "@" ]; then
	CHAIN_PASSWORD=$(cat ${CHAIN_PASSWORD:1})
fi

if [ -z "$CA_NAME" ] || [ ${#CA_NAME} -lt 1 ] ; 
then
	echo "Missing parameter CA_NAME or it was less than 1 characters in length, for intermediate certificate name, this is required."
	exit 1
fi

if [ -z "$CA_PASSWORD" ] || [ ${#CA_PASSWORD} -lt 4 ] ;
then
	echo "Missing parameter CA_PASSWORD or it was less than 4 characters in length, for intermediate certificate password, this is required."
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

if [ -z "$INSERT_CA_INTO_TRUSTED_CERTS" ] ;
then
	INSERT_CA_INTO_TRUSTED_CERTS=NO
fi

if [ "$EUID" -ne 0 ] && [ "$INSERT_CA_INTO_TRUSTED_CERTS" = "YES" ] ; 
then 
  echo $NO_ROOT_ON_INSERT_TO_CA_STORE
  exit 1
fi


CA_CERT_FQN=$CA_PREFIX$CA_NAME
CA_CONFIG_FILE=$CA_CERT_FQN$EXTENSION_FILE_EXTENSION

# Check if the config file does not exist
if [ ! -f $CA_CONFIG_FILE ] ;
then
	echo "The config file $CA_CONFIG_FILE does not exist, please create it first."
	exit 1
fi

CA_CHAIN_FQN=$ROOT_CA_PREFIX$CHAIN_NAME
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

printf "# Root Directory: %s\n# CA Name: %s\n# Intermediate CA Name: %s\nRootCA: %s\nIntermediate CA: %s\nIntermediate CA PFX: %s\n" $PWD $CA_CHAIN_FQN $CA_CERT_FQN "$CHAIN_PASSWORD" "$CA_PASSWORD" "$PFX_PASSWORD"
printf "# Root Directory: %s\n# CA Name: %s\n# Intermediate CA Name: %s\nRootCA: %s\nIntermediate CA: %s\nIntermediate CA PFX: %s\n" $PWD $CA_CHAIN_FQN $CA_CERT_FQN "$CHAIN_PASSWORD" "$CA_PASSWORD" "$PFX_PASSWORD" > $CA_CERT_FQN.credentials.txt

# Certificate's password
printf "%s" "$CA_PASSWORD" > $CA_CERT_PASSWORD_FILE_NAME

# private key
openssl genrsa -des3 -passout pass:"$CA_PASSWORD" -out $CA_KEY_FILE_NAME $KEY_LENGTH

# get unencrypted private key
openssl rsa -in $CA_KEY_FILE_NAME -out $UNENCRYPTED_CA_KEY_FILE_NAME -passin pass:"$CA_PASSWORD"

# generate certificate signing request
openssl req -new -key $CA_KEY_FILE_NAME -passin pass:"$CA_PASSWORD" -out $CA_CERTIFICATE_REQUEST_FILE_NAME -config $CA_CONFIG_FILE

# generate certificate
openssl x509 -req -days $EXPIRATION_IN_DAYS -in $CA_CERTIFICATE_REQUEST_FILE_NAME -CA $CA_CHAIN_FILE_NAME -CAkey $CA_CHAIN_KEY_FILE_NAME -CAcreateserial -passin pass:"$CHAIN_PASSWORD" -out $CA_CERT_FILE_NAME -sha256 -extfile $CA_CONFIG_FILE -extensions config_extensions

# generate pfx
openssl pkcs12 -export -passin pass:"$CA_PASSWORD" -password pass:"$PFX_PASSWORD" -out $CA_CERT_PFX_FILE_NAME -inkey $CA_KEY_FILE_NAME -in $CA_CERT_FILE_NAME -CAfile $CA_CHAIN_FILE_NAME

# extract pem from pfx
openssl pkcs12 -password pass:"$PFX_PASSWORD" -in $CA_CERT_PFX_FILE_NAME -out $CA_CERT_PEM_FILE_NAME -nodes

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
