#!/bin/sh

# Get the location that we should save files from
INPUT_DIR=$1

# The data will be sliced to ensure each data fragment is at most 500,000 bytes (500 kB)
DATA_SIZE_BYTES=500000

# Load the helper functions
. $HELPER_FUNC

# Create tar archive from folder - give it a randomized name so it doesn't overwrite any existing files
DATA_TAR=data.$(generate_uuid).tar.gz
tar -czvf $DATA_TAR ${INPUT_DIR}/

# Clean working directory
FRAGMENTS_DIR=fragments
rm -rf $FRAGMENTS_DIR/*
mkdir -p $FRAGMENTS_DIR

# Split tar archive into file fragments
split --unbuffered --numeric-suffixes --suffix-length=3 --bytes=$DATA_SIZE_BYTES "$DATA_TAR" "${FRAGMENTS_DIR}/${DATA_TAR}."

# Iterate over file fragments in order
METADATA=""
for FILEPATH in "$FRAGMENTS_DIR"/*; do
    # Get the filename without the path
    FILENAME=$(basename $FILEPATH)

    # Save this filename as a line in the metadata variable
    METADATA="${METADATA}${FILENAME}"$'\n'

    # Convert file fragment to a base64 encoded string
    BASE64_FRAGMENT=$(base64 -w 0 "$(cat $FILEPATH)")

    # Save the data fragment
    save_data "$FILENAME" "$BASE64_FRAGMENT"
done

# If there were any data fragments that were saved, save the metadata as well
if ! [ -z "$METADATA" ]; then
    # First get the names of old data fragments (from the old metadata) that we no longer need
    OLD_FRAGMENTS=$(get_data "$PERSIST_NAME")

    # Save the metadata (i.e. overwrite the old metadata)
    save_data "$PERSIST_NAME" "$METADATA"

    # Delete the old data fragments
    while IFS= read -r OLD_FRAGMENT_NAME; do
        if ! [ -z $OLD_FRAGMENT_NAME ]; do
            # Delete the old data fragment
            delete_data "$OLD_FRAGMENT_NAME"
        fi
    done < <(echo "$OLD_FRAGMENTS")
fi

# Clean up temporary files
rm -rf $FRAGMENTS_DIR
rm -rf $DATA_TAR