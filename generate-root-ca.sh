#!/bin/bash

# Constants
OUT_FILE="# Command: %s/generate-root-ca.sh %s %s %s %s\n# Root Directory: %s\n# RootCA Name: %s\nRootCA: %s\nRootCA PFX: %s\n"
NO_ROOT_ON_INSERT_TO_CA_STORE="This requires you to run as root if you want to insert the root certificate into the current machine's root certificate authority. If you don't want to insert it into the root certificate authority, please set the fourth parameter of this command to \"NO\"."
CERT_BIN=$PWD/bin
ROOT_CA_PREFIX=$CERT_BIN/mfdlabs-root-ca-
CA_CERTS_STORE=/usr/local/share/ca-certificates/

# Variables

ROOT_CA_NAME=$1
ROOT_CA_PASSWORD=$2
PFX_PASSWORD=$3
INSERT_ROOT_CA_INTO_TRUSTED_CERTS=$4
DO_NOT_GENERATE_DHPARAM=$5

if [ -z "$INSERT_ROOT_CA_INTO_TRUSTED_CERTS" ] ;
then
	INSERT_ROOT_CA_INTO_TRUSTED_CERTS=YES
fi

if [ "$EUID" -ne 0 ] && [ "$INSERT_ROOT_CA_INTO_TRUSTED_CERTS" = "YES" ] ; 
then 
  echo $NO_ROOT_ON_INSERT_TO_CA_STORE
  exit 1
fi


if [ -z "$ROOT_CA_NAME" ] || [ ${#ROOT_CA_NAME} -le 1 ] ; 
then
	echo "Missing parameter at index 0 or it was less than 1 or equal to characters in length, for root certificate name, this is required."
	exit 1
fi

if [ -z "$ROOT_CA_PASSWORD" ] || [ ${#ROOT_CA_PASSWORD} -le 4 ] ;
then
	echo "Missing parameter at index 1 or it was less than 4 equal to characters in length, for root certificate password, this is required."
	exit 1
fi

if [ -z "$PFX_PASSWORD" ] || [ ${#PFX_PASSWORD} -le 4 ] ;
then
	echo "Missing parameter at index 2 or it was less than 4 equal to characters in length, for intermediate certificate pfx password, this is required."
	exit 1
fi

if [ -z "$DO_NOT_GENERATE_DHPARAM" ] ;
then
	DO_NOT_GENERATE_DHPARAM=NO
fi


printf $OUT_FILE $PWD $ROOT_CA_NAME $ROOT_CA_PASSWORD $PFX_PASSWORD $DO_NOT_GENERATE_DHPARAM $PWD $ROOT_CA_PREFIX$ROOT_CA_NAME $ROOT_CA_PASSWORD $PFX_PASSWORD
printf $OUT_FILE $PWD $ROOT_CA_NAME $ROOT_CA_PASSWORD $PFX_PASSWORD $DO_NOT_GENERATE_DHPARAM $PWD $ROOT_CA_PREFIX$ROOT_CA_NAME $ROOT_CA_PASSWORD $PFX_PASSWORD > $ROOT_CA_PREFIX$ROOT_CA_NAME.credentials.txt
printf "%s" $ROOT_CA_PASSWORD > $ROOT_CA_PREFIX$ROOT_CA_NAME-password.txt
openssl genrsa -des3 -passout pass:$ROOT_CA_PASSWORD -out $ROOT_CA_PREFIX$ROOT_CA_NAME.key 4096
openssl rsa -in $ROOT_CA_PREFIX$ROOT_CA_NAME.key -out $ROOT_CA_PREFIX$ROOT_CA_NAME.unencrypted.key -passin pass:$ROOT_CA_PASSWORD
openssl req -x509 -new -nodes -key $ROOT_CA_PREFIX$ROOT_CA_NAME.key -sha256 -days 4086 -passin pass:$ROOT_CA_PASSWORD -out $ROOT_CA_PREFIX$ROOT_CA_NAME.crt
openssl pkcs12 -export -passin pass:$ROOT_CA_PASSWORD -password pass:$PFX_PASSWORD -out $ROOT_CA_PREFIX$ROOT_CA_NAME.pfx -inkey $ROOT_CA_PREFIX$ROOT_CA_NAME.key -in $ROOT_CA_PREFIX$ROOT_CA_NAME.crt

if [ "$INSERT_ROOT_CA_INTO_TRUSTED_CERTS" = "YES" ] ;
then
	cp $ROOT_CA_PREFIX$ROOT_CA_NAME.crt $CA_CERTS_STORE$ROOT_CA_PREFIX$ROOT_CA_NAME.crt --force
fi

if [ "$DO_NOT_GENERATE_DHPARAM" = "NO" ] ;
then
	openssl dhparam -in $ROOT_CA_PREFIX$ROOT_CA_NAME.crt -out $ROOT_CA_PREFIX$ROOT_CA_NAME-dhparam.pem 4096
fi