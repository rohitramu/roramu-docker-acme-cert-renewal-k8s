#!/bin/sh

# Get the location that we should load files to
OUTPUT_DIR=$1

# Load the helper functions
. $HELPER_FUNC

# Get metadata object
TO_GET=$(get_data $PERSIST_NAME)

# Only attempt to restore if we found the value
if [ -z "$TO_GET" ]; then
    echo "WARNING: No data was found that could be restored.  Continuing without loading files..."
    exit
fi

# Clean working directory
FRAGMENTS_DIR=fragments
rm -rf $FRAGMENTS_DIR/*
mkdir -p $FRAGMENTS_DIR

# Get data fragments
while IFS= read -r DATA_FRAGMENT_NAME; do
    if ! [ -z "$DATA_FRAGMENT_NAME" ]; do
        # Get next data fragment
        DATA_FRAGMENT=$(get_data $DATA_FRAGMENT_NAME)

        # Restore file fragment from base64 encoded string and save it to a file
        base64 --decode $DATA_FRAGMENT > $FRAGMENTS_DIR/$DATA_FRAGMENT_NAME
    fi
done < <(echo "$TO_GET")

# Combine data fragments into a single tar file
DATA_TAR=restored_data.tar.gz
cat $FRAGMENTS_DIR/* > $DATA_TAR

# Extract restored tar file to output folder
tar -xzvf $DATA_TAR -C $OUTPUT_DIR/

# Clean up temporary files
rm -rf $FRAGMENTS_DIR
rm -rf $DATA_TAR
