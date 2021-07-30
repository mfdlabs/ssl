#!/bin/bash

# Constants
OUT_FILE="# Command: %s/generate-certs-v2.sh %s %s %s %s %s %s\n# Root Directory: %s\n# RootCA Name: %s\n# Intermediate Cert Name: %s\nRootCA: %s\nIntermediate Cert: %s\nIntermediate Cert PFX: %s\n"
NO_ROOT_ON_INSERT_TO_CA_STORE="This requires you to run as root if you want to insert the root certificate into the current machine's root certificate authority. If you don't want to insert it into the root certificate authority, please set the sixth parameter of this command to \"NO\"."
ROOT_CA_PREFIX=CERT_BIN=$PWD/bin
ROOT_CA_PREFIX=$CERT_BIN/mfdlabs-root-ca-
ALL_AUTHORITHY_PREFIX=$CERT_BIN/mfdlabs-all-authority-
CA_CERTS_STORE=/usr/local/share/ca-certificates/

ROOT_CA_NAME=$1
ROOT_CA_PASSWORD=$2
CERT_NAME=$3
CERT_PASSWORD=$4
PFX_PASSWORD=$5
INSERT_ROOT_CA_INTO_TRUSTED_CERTS=$6
DO_NOT_GENERATE_DHPARAM=$7

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
	echo "Missing parameter at index 0 or it was less than 3 or equal to characters in length, for root certificate name, this is required."
	exit 1
fi

if [ -z "$ROOT_CA_PASSWORD" ] || [ ${#ROOT_CA_PASSWORD} -le 4 ] ;
then
	echo "Missing parameter at index 1 or it was less than 4 equal to characters in length, for root certificate password, this is required."
	exit 1
fi

if [ -z "$CERT_NAME" ] || [ ${#CERT_NAME} -le 1 ] ; 
then
	echo "Missing parameter at index 2 or it was less than 1 or equal to characters in length, for intermediate certificate name, this is required."
	exit 1
fi

if [ -z "$CERT_PASSWORD" ] || [ ${#CERT_PASSWORD} -le 4 ] ;
then
	echo "Missing parameter at index 3 or it was less than 4 equal to characters in length, for intermediate certificate password, this is required."
	exit 1
fi

if [ -z "$PFX_PASSWORD" ] || [ ${#PFX_PASSWORD} -le 4 ] ;
then
	echo "Missing parameter at index 4 or it was less than 4 equal to characters in length, for intermediate certificate pfx password, this is required."
	exit 1
fi

if [ -z "$DO_NOT_GENERATE_DHPARAM" ] ;
then
	DO_NOT_GENERATE_DHPARAM=NO
fi

printf $OUT_FILE $PWD $ROOT_CA_NAME $ROOT_CA_PASSWORD $CERT_NAME $CERT_PASSWORD $PFX_PASSWORD $DO_NOT_GENERATE_DHPARAM $PWD $ROOT_CA_PREFIX$ROOT_CA_NAME $ALL_AUTHORITHY_PREFIX$CERT_NAME $ROOT_CA_PASSWORD $CERT_PASSWORD $PFX_PASSWORD
printf $OUT_FILE $PWD $ROOT_CA_NAME $ROOT_CA_PASSWORD $CERT_NAME $CERT_PASSWORD $PFX_PASSWORD $DO_NOT_GENERATE_DHPARAM $PWD $ROOT_CA_PREFIX$ROOT_CA_NAME $ALL_AUTHORITHY_PREFIX$CERT_NAME $ROOT_CA_PASSWORD $CERT_PASSWORD $PFX_PASSWORD > $ALL_AUTHORITHY_PREFIX$CERT_NAME.credentials.txt
printf "%s" $CERT_PASSWORD > $ALL_AUTHORITHY_PREFIX$CERT_NAME-password.txt
openssl genrsa -des3 -passout pass:$CERT_PASSWORD -out $ALL_AUTHORITHY_PREFIX$CERT_NAME.key 4096
openssl rsa -in $ALL_AUTHORITHY_PREFIX$CERT_NAME.key -out $ALL_AUTHORITHY_PREFIX$CERT_NAME.unencrypted.key -passin pass:$CERT_PASSWORD
openssl req -new -key $ALL_AUTHORITHY_PREFIX$CERT_NAME.key -passin pass:$CERT_PASSWORD -out $ALL_AUTHORITHY_PREFIX$CERT_NAME.csr -config $ALL_AUTHORITHY_PREFIX$CERT_NAME.conf
openssl x509 -req -days 4000 -in $ALL_AUTHORITHY_PREFIX$CERT_NAME.csr -CA $ROOT_CA_PREFIX$ROOT_CA_NAME.crt -CAkey $ROOT_CA_PREFIX$ROOT_CA_NAME.key -CAcreateserial -passin pass:$ROOT_CA_PASSWORD -out $ALL_AUTHORITHY_PREFIX$CERT_NAME.crt -sha256 -extfile $ALL_AUTHORITHY_PREFIX$CERT_NAME.conf -extensions config_extensions
openssl pkcs12 -export -passin pass:$CERT_PASSWORD -password pass:$PFX_PASSWORD -out $ALL_AUTHORITHY_PREFIX$CERT_NAME.pfx -inkey $ALL_AUTHORITHY_PREFIX$CERT_NAME.key -in $ALL_AUTHORITHY_PREFIX$CERT_NAME.crt -CAfile $ROOT_CA_PREFIX$ROOT_CA_NAME.crt

if [ "$INSERT_ROOT_CA_INTO_TRUSTED_CERTS" = "YES" ] ;
then
	cp $ROOT_CA_PREFIX$ROOT_CA_NAME.crt $CA_CERTS_STORE$ROOT_CA_PREFIX$ROOT_CA_NAME.crt --force
fi

rm $ALL_AUTHORITHY_PREFIX$CERT_NAME.csr --force --verbose

if [ "$DO_NOT_GENERATE_DHPARAM" = "NO" ] ;
then
	openssl dhparam -in $ALL_AUTHORITHY_PREFIX$CERT_NAME.crt -out $ALL_AUTHORITHY_PREFIX$CERT_NAME-dhparam.pem 4096
fi
