#!/bin/bash

###############################################################################
# Pi Kappa Phi Album Reset Script
#
# This script reverses the upload.sh process, converting a web-ready album
# back to its original state (just original photos in the root album directory).
# This makes it easier to change album details or add additional photos.
#
# Usage:
#   ./reset-album.sh [album-name]
#   or run without arguments to be prompted
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base directory for albums
ALBUMS_DIR="public/albums"

###############################################################################
# Helper Functions
###############################################################################

# Print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

###############################################################################
# Main Functions
###############################################################################

# List all available albums
list_albums() {
    local albums=()

    if [ ! -d "$ALBUMS_DIR" ]; then
        print_error "Albums directory not found: $ALBUMS_DIR"
        exit 1
    fi

    for album_dir in "$ALBUMS_DIR"/*/ ; do
        if [ -d "$album_dir" ]; then
            albums+=("$(basename "$album_dir")")
        fi
    done

    echo "${albums[@]}"
}

# Prompt user to select an album
select_album() {
    local albums=($(list_albums))
    local album_count=${#albums[@]}

    if [ $album_count -eq 0 ]; then
        print_error "No albums found in $ALBUMS_DIR"
        exit 1
    fi

    echo ""
    print_info "Available albums:"
    echo ""

    for i in "${!albums[@]}"; do
        printf "  %2d) %s\n" $((i + 1)) "${albums[$i]}"
    done

    echo ""
    read -p "Enter album number or name: " selection

    # Check if selection is a number
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        # Selection is a number
        local index=$((selection - 1))
        if [ $index -ge 0 ] && [ $index -lt $album_count ]; then
            echo "${albums[$index]}"
        else
            print_error "Invalid selection"
            exit 1
        fi
    else
        # Selection is a name
        echo "$selection"
    fi
}

# Reset an album to original state
reset_album() {
    local album_name="$1"
    local album_path="${ALBUMS_DIR}/${album_name}"

    # Check if album exists
    if [ ! -d "$album_path" ]; then
        print_error "Album not found: $album_name"
        exit 1
    fi

    print_info "Resetting album: $album_name"
    echo ""

    # Check if album has a data.json (is initialized)
    if [ ! -f "${album_path}/data.json" ]; then
        print_warning "Album is already in original state (no data.json found)"
        exit 0
    fi

    # Count photos in /full directory
    if [ ! -d "${album_path}/full" ]; then
        print_error "No /full directory found. Album may be corrupted."
        exit 1
    fi

    photo_count=$(find "${album_path}/full" -type f | wc -l)
    print_info "Found $photo_count photo(s) to restore"

    # Confirm reset
    echo ""
    print_warning "This will:"
    print_warning "  - Move all photos from /full back to album root"
    print_warning "  - Delete the /low directory and all thumbnails"
    print_warning "  - Delete the /full directory"
    print_warning "  - Delete the data.json file"
    echo ""
    read -p "Are you sure you want to reset this album? (y/n): " confirm

    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_info "Reset cancelled"
        exit 0
    fi

    echo ""

    # Move photos from /full to album root
    print_info "Moving photos from /full to album root..."
    mv "${album_path}/full"/* "${album_path}/"
    print_success "Photos moved"

    # Delete /low directory
    if [ -d "${album_path}/low" ]; then
        print_info "Deleting /low directory..."
        rm -rf "${album_path}/low"
        print_success "Thumbnails deleted"
    fi

    # Delete /full directory
    print_info "Deleting /full directory..."
    rm -rf "${album_path}/full"
    print_success "Full directory deleted"

    # Delete data.json
    if [ -f "${album_path}/data.json" ]; then
        print_info "Deleting data.json..."
        rm "${album_path}/data.json"
        print_success "Metadata deleted"
    fi

    echo ""
    print_success "Album '$album_name' has been reset to original state!"
    print_info "The album now contains $photo_count original photo(s)"
    print_info "You can now:"
    print_info "  - Add more photos to the album directory"
    print_info "  - Run ./upload.sh to re-process the album"
    echo ""
}

###############################################################################
# Main Script Execution
###############################################################################

main() {
    echo ""
    print_info "=== Pi Kappa Phi Album Reset Script ==="
    echo ""

    # Check if album name provided as argument
    if [ -n "$1" ]; then
        album_name="$1"
    else
        # Prompt user to select album
        album_name=$(select_album)
    fi

    # Reset the selected album
    reset_album "$album_name"

    print_success "Done! 🎉"
    echo ""
}

# Run main function
main "$@"
