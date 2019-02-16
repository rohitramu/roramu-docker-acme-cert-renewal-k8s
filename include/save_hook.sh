#!/bin/sh

# Get the location that we should save files from
INPUT_DIR=$1

# The data will be sliced to ensure each data fragment is at most 500,000 bytes (500 kB)
DATA_SIZE_BYTES=500000

# Load the helper functions
. $HELPER_FUNC

# Create tar archive from folder - give it a randomized name so it doesn't overwrite any existing files
DATA_TAR="${PERSIST_NAME}.$(generate_uuid).tar.gz"
echo "Creating tar file..."
tar -czvf $DATA_TAR -C $INPUT_DIR .
echo "Finished creating tar file"
echo ""

# Clean working directory
FRAGMENTS_DIR="fragments"
mkdir -p $FRAGMENTS_DIR
rm -rf $FRAGMENTS_DIR/*

# Split tar archive into file fragments
split --unbuffered --numeric-suffixes --suffix-length=3 --bytes=$DATA_SIZE_BYTES "$DATA_TAR" "$FRAGMENTS_DIR/$DATA_TAR."

# Iterate over file fragments in order
echo "Storing file fragments..."
FRAGMENT_MANIFEST_FILE="fragment_manifest.txt"
rm -rf $FRAGMENT_MANIFEST_FILE
for FILEPATH in "$FRAGMENTS_DIR"/*; do
    # Get the filename without the path
    FILENAME=$(basename $FILEPATH)

    # Save this filename as a line in the metadata variable
    echo "$FILENAME" >> $FRAGMENT_MANIFEST_FILE

    # Save the data fragment in the file
    save_data "$FILENAME" "$FILEPATH"
done
echo "Finished storing file fragments"
echo ""

# If there were any data fragments that were saved, save the metadata as well
if test -f "$FRAGMENT_MANIFEST_FILE"; then
    echo "Saving file fragment metadata..."

    # First get the names of old data fragments (from the old metadata) that we no longer need
    OLD_FRAGMENTS=$(get_data "$PERSIST_NAME" .)

    # Save the metadata (i.e. overwrite the old metadata)
    save_data "${PERSIST_NAME}.manifest" "$FRAGMENT_MANIFEST_FILE"

    # Delete the old data fragments if we found an old manifest
    if test -f $OLD_FRAGMENTS; then
        while IFS="" read -r OLD_FRAGMENT_NAME; do
            if ! [ -z "$OLD_FRAGMENT_NAME" ]; then
                # Delete the old data fragment
                delete_data "$OLD_FRAGMENT_NAME"
            fi
        done < $OLD_FRAGMENTS
    fi

    echo "Finished saving file fragment metadata"
    echo ""
fi

# Clean up temporary files
rm -rf $FRAGMENTS_DIR
rm -rf $DATA_TAR