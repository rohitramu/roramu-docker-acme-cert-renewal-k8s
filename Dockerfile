#
# +---------------------+
# | Usage of this image |
# +---------------------+
# - The ENTRYPOINT or CMD commands SHOULD NOT be overridden in child images.
# - The following environment variables MUST be provided:
#       - $ACME_SERVER: The ACME server that will be used.  If this is not set, it will default to the
#         "Let's Encrypt" staging URL.  Any ACME server URL may be provided.  For reference, the
#         "Let's Encrypt" v2 certificate authority URLs are:
#             - Staging:    https://acme-staging-v02.api.letsencrypt.org/directory
#             - Production: https://acme-v02.api.letsencrypt.org/directory
#       - $DOMAIN: Domain name for which a certificate should be generated/renewed.
#       - $AUTH_DOMAIN: Authentication domain, where the DNS challenge will take place (i.e. TXT records
#         are created here).
#       - $CERT_EMAIL: The email address to be included in the certificate.
# - The following environment variables SHOULD be provided:
#       - $SECRET_NAME: The name of the Kubernetes TLS secret to create.  If not provided, this will
#         default to "tls-secret".
#       - $SECRET_NAMESPACE: The name of the Kubernetes namespace in which the secret will be created.
#         If not provided, this will default to "frontend".
# - Inbound ports that need to be open to the internet:
#       - 53/udp
#       - 53/tcp (optional)
# - Outbound ports that need to be open to the internet:
#       - 80/tcp
#       - 443/tcp
# - The following DNS records should be placed in the DNS zone specified by $DOMAIN in order for the
#   ACME challenge to work:
#      1. CNAME record that points from "$CERT_CHALLENGE_SUBDOMAIN.$DOMAIN" to
#         "$CERT_CHALLENGE_SUBDOMAIN.$AUTH_DOMAIN"
#      2. NS record that points to the server that this image is running on.
#
FROM rohitramu/acme-cert-renewal:latest

RUN echo "" && \
    # Install runtime tools
    echo "+-----------------+" && \
    echo "| Install kubectl |" && \
    echo "+-----------------+" && \
    apk add --update ca-certificates && \
    curl -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    echo "" && \
    echo "" && \
    # Clean up
    echo "+---------------------+" && \
    echo "| Clean package cache |" && \
    echo "+---------------------+" && \
    rm /var/cache/apk/* && \
    echo "" && \
    echo "" && \
    echo "+------------------------------+" && \
    echo "| Finished installing packages |" && \
    echo "+------------------------------+" && \
    echo ""

# Make sure we're working in the correct folder (specified by the parent image)
WORKDIR $WORKING_DIR

# Copy files
COPY include/ .

# Make included files executable
RUN find ./ -type f -exec chmod +x {} \;

# Set the environment variables that will help to store persisted data
# WARNING: These MUST NOT be modified
ENV \
    # The name of the Kubernetes secret that holds the names of the other secrets
    # which contain fragments of the persisted data
    PERSIST_NAME="acme-cert-renewal" \
    # The location of helper functions that are used by the hook scripts
    HELPER_FUNC="$WORKING_DIR/k8s_helpers.sh"

# Set the environment variables that specify the hook commands
ENV \
    # Deploy hook
    DEPLOY_HOOK="$WORKING_DIR/deploy_hook.sh" \
    # Load hook
    LOAD_HOOK="$WORKING_DIR/load_hook.sh" \
    # Save hook
    SAVE_HOOK="$WORKING_DIR/save_hook.sh"

# Choose the name and namespace of the TLS secret by setting these variables
# These MUST be set to non-empty values
ENV \
    # Kubernetes secret name
    SECRET_NAME="tls-secret" \
    # Kubernetes namespace for the secret
    SECRET_NAMESPACE="frontend"
