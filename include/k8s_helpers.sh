#!/bin/sh

# Retrieves a persisted data item, given its name
get_data()
{
    kubectl get secrets $1 --ignore-not-found -o 'go-template={{ .data.value }}'
}

# Saves a persisted data fragment, given its name and value
save_data()
{
    kubectl create secret generic $1 --from-literal value=$2 --dry-run -o yaml | kubectl apply -f -
}

# Deletes a persisted data fragment, given its name
delete_data()
{
    kubectl delete secret --ignore-not-found --force --now $1
}

# Deploys a certificate given the secret name, secret namespace, private key file and certificate file
deploy_cert()
{
    kubectl create secret tls $1 --namespace=$2 --key=$3 --cert=$4 --dry-run -o yaml | kubectl apply -f -
}

# Generates a new UUID
generate_uuid()
{
    cat /proc/sys/kernel/random/uuid
}