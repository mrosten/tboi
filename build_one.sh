#!/bin/bash
set -e

# Parse arguments
LANGUAGE="${1:-he}"
FILE_PATH="${2:-}"

if [ -z "$FILE_PATH" ]; then
    echo "Usage: $0 [en|he] <file_path>"
    echo "Example: $0 he parts/part_iii_life/chapter_07-saints/section_i.html"
    exit 1
fi

if [[ "$LANGUAGE" != "en" && "$LANGUAGE" != "he" ]]; then
    echo "Language must be 'en' or 'he'"
    exit 1
fi

echo "Starting Quick Build for $FILE_PATH ($LANGUAGE)..."

# Get the script's directory (root of project)
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Setup paths based on language
if [ "$LANGUAGE" = "he" ]; then
    DEST_FILE="$ROOT_DIR/he/$FILE_PATH"
    SPLIT_BOOK_DIR="$ROOT_DIR/split_book_he"
else
    DEST_FILE="$ROOT_DIR/$FILE_PATH"
    SPLIT_BOOK_DIR="$ROOT_DIR/split_book"
fi

DEST_DIR="$(dirname "$DEST_FILE")"

# Extract filename and chapter folder
FILENAME=$(basename "$FILE_PATH" .html)
CHAPTER_FOLDER=$(basename "$(dirname "$FILE_PATH")")

# Find the source text file
SRC_FILE=$(find "$SPLIT_BOOK_DIR" -name "$FILENAME.txt" -path "*$CHAPTER_FOLDER*" | head -1)

if [ -z "$SRC_FILE" ]; then
    echo "Error: Could not find source text file for $FILENAME in $SPLIT_BOOK_DIR matching chapter $CHAPTER_FOLDER"
    exit 1
fi

echo "Found source: $SRC_FILE"

# Read source content
CONTENT=$(cat "$SRC_FILE")
CHAR_COUNT=${#CONTENT}
echo "Read $CHAR_COUNT chars from $SRC_FILE"

# Convert content to HTML fragment
# Handle Title
CONTENT=$(echo "$CONTENT" | sed -E 's/\[TITLE:\s*(.*?)\]/<h1>\1<\/h1>/g')

# Determine depth based on language
if [ "$LANGUAGE" = "he" ]; then
    DEPTH="../../../.."
else
    DEPTH="../../.."
fi

# Handle Images
CONTENT=$(echo "$CONTENT" | sed -E "s|\[IMAGE:\s*(.*?)\]|<div class='image-container'><img src='$DEPTH/images/\1' alt='Book Image' class='book-image'></div>|g")

# Handle formatting
CONTENT=$(echo "$CONTENT" | sed -E 's/\*\*(.*?)\*\*/<strong>\1<\/strong>/g')
CONTENT=$(echo "$CONTENT" | sed -E 's/\*(.*?)\*/<em>\1<\/em>/g')

echo "Content length after processing: ${#CONTENT} chars"

# Verify destination file exists
if [ ! -f "$DEST_FILE" ]; then
    echo "Error: Destination HTML file not found: $DEST_FILE"
    echo "Run full build first to generate key structure."
    exit 1
fi

# Read destination HTML
HTML=$(cat "$DEST_FILE")

# Find the main tag
MAIN_START=$(grep -bo '<main[^>]*>' "$DEST_FILE" | head -1 | cut -d: -f1)

if [ -z "$MAIN_START" ]; then
    echo "Error: Could not find <main> tag in $DEST_FILE"
    exit 1
fi

# Find the page-nav div
PAGE_NAV_START=$(grep -bo '<div class="page-nav">' "$DEST_FILE" | head -1 | cut -d: -f1)

if [ -z "$PAGE_NAV_START" ]; then
    PAGE_NAV_START=$(grep -bo "<div class='page-nav'>" "$DEST_FILE" | head -1 | cut -d: -f1)
fi

if [ -z "$PAGE_NAV_START" ]; then
    echo "Error: Could not find <div class='page-nav'> in $DEST_FILE"
    exit 1
fi

# Extract parts
# Get everything up to and including the opening <main> tag
PRE_MAIN=$(head -c $((MAIN_START + 200)) "$DEST_FILE" | tail -c 220)
MAIN_TAG_END=$(echo "$PRE_MAIN" | grep -o '<main[^>]*>' | head -1)
PRE_MAIN=$(echo "$HTML" | head -c $((MAIN_START + ${#MAIN_TAG_END})))

# Get everything from page-nav onwards
POST_CONTENT=$(tail -c +$((PAGE_NAV_START + 1)) "$DEST_FILE")

# Construct new HTML using a temporary file
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

{
    echo "$PRE_MAIN"
    echo ""
    echo "$CONTENT"
    echo ""
    echo "$POST_CONTENT"
} > "$TEMP_FILE"

# Move temp file to destination
mv "$TEMP_FILE" "$DEST_FILE"
echo "Updated HTML content in $DEST_FILE"

# Ensure destination directory exists for images
if [ "$LANGUAGE" = "he" ]; then
    IMAGES_DIR="$ROOT_DIR/he/images"
else
    IMAGES_DIR="$ROOT_DIR/images"
fi

mkdir -p "$IMAGES_DIR"

# Copy images if source differs from dest
SRC_IMAGES="$ROOT_DIR/images"
if [ "$SRC_IMAGES" != "$IMAGES_DIR" ]; then
    if [ -d "$SRC_IMAGES" ]; then
        cp -r "$SRC_IMAGES"/* "$IMAGES_DIR/" 2>/dev/null || true
        echo "Copied images to $IMAGES_DIR"
    fi
else
    echo "Skipping image copy (Source == Destination)"
fi

# Copy styles.css if Hebrew
if [ "$LANGUAGE" = "he" ]; then
    CSS_DEST="$ROOT_DIR/he/styles.css"
    if [ -f "$ROOT_DIR/styles.css" ]; then
        cp "$ROOT_DIR/styles.css" "$CSS_DEST"
        echo "Copied styles.css to $CSS_DEST"
    fi
fi

echo "Done."
