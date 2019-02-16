#!/bin/sh

# Get the location that we should load files to
OUTPUT_DIR=$1

# Load the helper functions
. $HELPER_FUNC

# Get metadata object
TO_GET=$(get_data "$PERSIST_NAME" .)

# Only attempt to restore if we found the value
if ! test -f "$TO_GET"; then
    echo "WARNING: No data was found that could be restored.  Continuing without loading files..."
    exit
fi

# Print the data we found
echo "Found data fragments to load:"
cat $TO_GET
echo ""

# Clean working directory
FRAGMENTS_DIR=fragments
mkdir -p $FRAGMENTS_DIR
rm -rf $FRAGMENTS_DIR/*

# Get data fragments
while IFS="" read -r DATA_FRAGMENT_NAME; do
    if ! [ -z "$DATA_FRAGMENT_NAME" ]; then
        # Get next data fragment and save it to a file inside $FRAGMENTS_DIR
        get_data "$DATA_FRAGMENT_NAME" "$FRAGMENTS_DIR"
    fi
done < $TO_GET

# Combine data fragments into a single tar file
DATA_TAR=restored_data.tar.gz
cat "$FRAGMENTS_DIR"/* > $DATA_TAR

# Extract restored tar file to output folder
tar -xzvf $DATA_TAR -C $OUTPUT_DIR/

# Clean up temporary files
rm -rf $FRAGMENTS_DIR
rm -rf $DATA_TAR
