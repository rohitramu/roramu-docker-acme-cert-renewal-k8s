#!/bin/sh

# The name of the key used in the secrets that store persisted data
VALUE_KEY="value"

# Generates a new UUID
generate_uuid()
{
    cat /proc/sys/kernel/random/uuid
}

# Trims all leading and trailing whitespace from a string
trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

# Deploys a certificate given the secret name, secret namespace, private key file and certificate file
deploy_cert()
{
    echo "Deploying cert..."

    SECRET_NAME=$1
    SECRET_NAMESPACE=$2
    KEY_FILE=$3
    CERT_FILE=$4

    echo "SECRET_NAME:      $SECRET_NAME"
    echo "SECRET_NAMESPACE: $SECRET_NAMESPACE"
    echo "KEY_FILE:         $KEY_FILE"
    echo "CERT_FILE:        $CERT_FILE"

    kubectl create secret tls $SECRET_NAME --namespace=$SECRET_NAMESPACE --key=$KEY_FILE --cert=$CERT_FILE --dry-run -o yaml | kubectl apply -f -

    echo "Finished deploying cert"
}

# Retrieves a persisted data item, given its name
get_data()
{
    echo "Retrieving persisted data..."

    DATA_ITEM_NAME=$1
    DATA_ITEM_DIR=$2

    echo "DATA_ITEM_NAME: $DATA_ITEM_NAME"
    echo "DATA_ITEM_DIR:  $DATA_ITEM_DIR"

    DATA_ITEM=$(trim "$(kubectl get secrets $DATA_ITEM_NAME --ignore-not-found -o "go-template={{ .data.${VALUE_KEY} }}")")

    if [ -z "$DATA_ITEM" ]; then
        # Restore file fragment from base64 encoded string
        OUTPUT_FILE=$DATA_ITEM_DIR/$DATA_ITEM_NAME
        base64 --decode $DATA_ITEM > $OUTPUT_FILE

        echo -n "$OUTPUT_FILE"
    fi

    echo "Finished retrieving persisted data"
}

# Saves a persisted data fragment, given its name and filepath
save_data()
{
    echo "Saving persisted data..."

    DATA_ITEM_NAME=$1
    DATA_ITEM_PATH=$2

    echo "DATA_ITEM_NAME: $DATA_ITEM_NAME"
    echo "DATA_ITEM_PATH: $DATA_ITEM_PATH"

    kubectl create secret generic $DATA_ITEM_NAME --from-file $VALUE_KEY=$DATA_ITEM_PATH --dry-run -o yaml | kubectl apply -f -

    echo "Finished saving persisted data"
}

# Deletes a persisted data fragment, given its name
delete_data()
{
    echo "Deleting persisted data..."

    DATA_ITEM_NAME=$1

    echo "DATA_ITEM_NAME: $DATA_ITEM_NAME"

    kubectl delete secret --ignore-not-found --force --now $DATA_ITEM_NAME

    echo "Finished deleting persisted data"
}
