#!/bin/sh

# The name of the key used in the secrets that store persisted data
VALUE_KEY="value"

# Deploys a certificate given the secret name, secret namespace, private key file and certificate file
deploy_cert()
{
    SECRET_NAME=$1
    SECRET_NAMESPACE=$2
    KEY_FILE=$3
    CERT_FILE=$4

    kubectl create secret tls $SECRET_NAME --namespace=$SECRET_NAMESPACE --key=$KEY_FILE --cert=$CERT_FILE --dry-run -o yaml | kubectl apply -f -
}

# Retrieves a persisted data item, given its name
get_data()
{
    DATA_ITEM_NAME=$1
    DATA_ITEM_DIR=$2

    DATA_ITEM=$(kubectl get secrets $DATA_ITEM_NAME --ignore-not-found -o "go-template={{ .data.${VALUE_KEY} }}")

    # Restore file fragment from base64 encoded string
    base64 --decode $DATA_ITEM > $DATA_ITEM_DIR/$DATA_ITEM_NAME

    echo "${DATA_ITEM_DIR}/${DATA_ITEM_NAME}"
}

# Saves a persisted data fragment, given its name and filepath
save_data()
{
    DATA_ITEM_NAME=$1
    DATA_ITEM_PATH=$2

    kubectl create secret generic $DATA_ITEM_NAME --from-file $VALUE_KEY=$DATA_ITEM_PATH --dry-run -o yaml | kubectl apply -f -
}

# Deletes a persisted data fragment, given its name
delete_data()
{
    DATA_ITEM_NAME=$1

    kubectl delete secret --ignore-not-found --force --now $DATA_ITEM_NAME
}

# Generates a new UUID
generate_uuid()
{
    cat /proc/sys/kernel/random/uuid
}