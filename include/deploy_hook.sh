#!/bin/sh

# Get arguments
DOMAIN=$1
KEY_FILE=$2
CERT_FILE=$3
FULL_CHAIN_CERT_FILE=$4
CHAIN_FILE=$5

# Load the helper functions
. $HELPER_FUNC

# Create/update secret
deploy_cert "$SECRET_NAME" "$SECRET_NAMESPACE" "$KEY_FILE" "$FULL_CHAIN_CERT_FILE"
