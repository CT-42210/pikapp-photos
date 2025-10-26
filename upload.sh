#!/bin/bash

###############################################################################
# Pi Kappa Phi Photo Upload Script
#
# This script processes photos for the photo gallery website:
# 1. Scans for uninitialized albums (no data.json)
# 2. Creates data.json with album metadata
# 3. Renames photos to snake_case format
# 4. Generates webP thumbnails (50% size)
# 5. Copies originals to /full folder
# 6. Renames album folder to snake_case
# 7. Deploys to git and Firebase (with confirmation)
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

# Convert string to snake_case
to_snake_case() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_'
}

# Check if ffmpeg is installed
check_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        print_error "ffmpeg is not installed. Please install it first:"
        print_info "  macOS: brew install ffmpeg"
        print_info "  Linux: sudo apt-get install ffmpeg"
        exit 1
    fi
}

###############################################################################
# Main Processing Functions
###############################################################################

# Find all uninitialized albums (folders without data.json)
find_uninitialized_albums() {
    if [ ! -d "$ALBUMS_DIR" ]; then
        print_warning "Albums directory not found: $ALBUMS_DIR"
        mkdir -p "$ALBUMS_DIR"
        print_success "Created albums directory"
    fi

    # Output album directories one per line to handle spaces in names
    for album_dir in "$ALBUMS_DIR"/*/ ; do
        if [ -d "$album_dir" ] && [ ! -f "${album_dir}data.json" ]; then
            echo "$album_dir"
        fi
    done
}

# Process a single album
process_album() {
    local album_path="$1"
    local album_dir_name=$(basename "$album_path")

    print_info "Processing album: $album_dir_name"
    echo ""

    # Get album metadata from user
    read -p "Enter album name (e.g., 'Spring Formal 2024'): " album_name
    read -p "Enter photographer name: " photographer_name

    # Generate timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Convert album name to snake_case for filenames
    snake_album_name=$(to_snake_case "$album_name")

    print_info "Album will be renamed to: $snake_album_name"
    echo ""

    # Count photos in album root (handle spaces in filenames)
    local photo_files=()
    while IFS= read -r -d '' file; do
        photo_files+=("$file")
    done < <(find "$album_path" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0)
    photo_count=${#photo_files[@]}

    if [ $photo_count -eq 0 ]; then
        print_warning "No photos found in album root directory. Skipping."
        return
    fi

    print_info "Found $photo_count photos to process"

    # Create low and full directories
    mkdir -p "${album_path}low"
    mkdir -p "${album_path}full"

    # Process each photo
    local index=1
    local cover_photo=""
    local photo_data=()  # Array to store: "webp_name:original_extension"

    for photo in "${photo_files[@]}"; do
        # Get file extension
        extension="${photo##*.}"
        extension_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

        # Generate new filenames
        base_name="${snake_album_name}_${index}"
        original_filename="${base_name}.${extension_lower}"
        webp_filename="${base_name}.webp"

        # Store photo data (webp name and original extension)
        photo_data+=("${webp_filename}:${extension_lower}")

        print_info "Processing photo $index/$photo_count: $(basename "$photo")"

        # Copy original to /full directory (for downloading only)
        cp "$photo" "${album_path}full/${original_filename}"
        print_success "  ✓ Copied original to full/"

        # Generate webP thumbnail at 50% size (for both thumbnails AND lightbox viewing)
        ffmpeg -i "$photo" -vf "scale=iw*0.5:ih*0.5" -quality 85 "${album_path}low/${webp_filename}" -y &> /dev/null
        print_success "  ✓ Generated webP thumbnail"

        # Delete original from album root
        rm "$photo"

        index=$((index + 1))
    done

    # Randomly select a cover photo
    random_index=$((RANDOM % ${#photo_data[@]}))
    cover_photo_data="${photo_data[$random_index]}"
    cover_photo_webp="${cover_photo_data%%:*}"

    print_info "Selected cover photo: $cover_photo_webp"

    # Build photos array for JSON (objects with webp and original extension)
    local photos_json="["
    for i in "${!photo_data[@]}"; do
        local webp_name="${photo_data[$i]%%:*}"
        local orig_ext="${photo_data[$i]##*:}"

        if [ $i -eq 0 ]; then
            photos_json="$photos_json\n    {\"webp\": \"$webp_name\", \"ext\": \"$orig_ext\"}"
        else
            photos_json="$photos_json,\n    {\"webp\": \"$webp_name\", \"ext\": \"$orig_ext\"}"
        fi
    done
    photos_json="$photos_json\n  ]"

    # Create data.json with photos array
    cat > "${album_path}data.json" <<EOF
{
  "name": "$album_name",
  "photographer": "$photographer_name",
  "date": "$timestamp",
  "coverPhoto": "$cover_photo_webp",
  "photos": $(echo -e "$photos_json")
}
EOF

    print_success "Created data.json"

    # Rename album directory to snake_case
    new_album_path="${ALBUMS_DIR}/${snake_album_name}"

    if [ "$album_path" != "${new_album_path}/" ]; then
        mv "$album_path" "$new_album_path"
        print_success "Renamed album directory to: $snake_album_name"
    fi

    echo ""
    print_success "Album '$album_name' processed successfully!"
    print_info "  - $photo_count photos processed"
    print_info "  - Thumbnails: $new_album_path/low/"
    print_info "  - Full size: $new_album_path/full/"
    print_info "  - Metadata: $new_album_path/data.json"
    echo ""
}

# Generate albums.json manifest
generate_albums_manifest() {
    print_info "Generating albums.json manifest..."

    if [ ! -d "$ALBUMS_DIR" ]; then
        print_warning "Albums directory not found"
        return
    fi

    # Find all album directories that have data.json
    local albums=()
    for album_dir in "$ALBUMS_DIR"/*/ ; do
        if [ -d "$album_dir" ] && [ -f "${album_dir}data.json" ]; then
            albums+=("$(basename "$album_dir")")
        fi
    done

    # Build JSON array
    local json_content="{\n  \"albums\": ["
    for i in "${!albums[@]}"; do
        if [ $i -eq 0 ]; then
            json_content="${json_content}\n    \"${albums[$i]}\""
        else
            json_content="${json_content},\n    \"${albums[$i]}\""
        fi
    done
    json_content="${json_content}\n  ]\n}"

    # Write to public/albums.json
    echo -e "$json_content" > "public/albums.json"

    print_success "Created albums.json with ${#albums[@]} album(s)"
}

# Deploy to git
deploy_to_git() {
    print_info "Preparing to deploy to git..."

    # Check if there are changes
    if git diff-index --quiet HEAD --; then
        print_warning "No changes to commit"
        return
    fi

    # Show git status
    print_info "Git status:"
    git status --short
    echo ""

    # Ask for confirmation
    read -p "Do you want to commit and push to git? (y/n): " confirm_git

    if [ "$confirm_git" != "y" ] && [ "$confirm_git" != "Y" ]; then
        print_warning "Git deployment skipped"
        return
    fi

    # Add all changes
    git add .

    # Create commit
    read -p "Enter commit message (or press Enter for default): " commit_msg

    if [ -z "$commit_msg" ]; then
        commit_msg="Add new album(s) to photo gallery"
    fi

    git commit -m "$commit_msg"
    print_success "Changes committed"

    # Push to remote
    git push
    print_success "Changes pushed to remote repository"
}

# Deploy to Firebase
deploy_to_firebase() {
    print_info "Preparing to deploy to Firebase..."

    # Check if firebase CLI is installed
    if ! command -v firebase &> /dev/null; then
        print_error "Firebase CLI is not installed. Please install it first:"
        print_info "  npm install -g firebase-tools"
        return
    fi

    # Ask for confirmation
    read -p "Do you want to deploy to Firebase? (y/n): " confirm_firebase

    if [ "$confirm_firebase" != "y" ] && [ "$confirm_firebase" != "Y" ]; then
        print_warning "Firebase deployment skipped"
        return
    fi

    # Deploy
    firebase deploy
    print_success "Deployed to Firebase"
}

# Deploy photos to nginx server
deploy_to_nginx() {
    print_info "Preparing to upload photos to nginx server..."

    # Configuration
    local NGINX_SERVER="pikapp-photos.ct-42210.com"
    local NGINX_USER="pikapp-photos"
    local NGINX_PATH="/var/www/pikapp-photos"

    # Check if rsync is installed
    if ! command -v rsync &> /dev/null; then
        print_error "rsync is not installed. Please install it first:"
        print_info "  macOS: brew install rsync"
        print_info "  Linux: sudo apt-get install rsync"
        return
    fi

    # Find all initialized albums (albums with /low and /full folders in public/albums)
    local albums_to_upload=()
    for album_dir in "$ALBUMS_DIR"/*/ ; do
        if [ -d "$album_dir" ] && [ -d "${album_dir}low" ] && [ -d "${album_dir}full" ]; then
            albums_to_upload+=("$(basename "$album_dir")")
        fi
    done

    if [ ${#albums_to_upload[@]} -eq 0 ]; then
        print_warning "No albums with photos found to upload"
        return
    fi

    print_info "Found ${#albums_to_upload[@]} album(s) to upload:"
    for album in "${albums_to_upload[@]}"; do
        echo "  - $album"
    done
    echo ""

    # Ask for confirmation
    read -p "Do you want to upload photos to nginx server ($NGINX_SERVER)? (y/n): " confirm_nginx

    if [ "$confirm_nginx" != "y" ] && [ "$confirm_nginx" != "Y" ]; then
        print_warning "Nginx upload skipped"
        return
    fi

    # Upload each album
    for album in "${albums_to_upload[@]}"; do
        print_info "Uploading album: $album"

        # Upload low and full folders using rsync
        # -a: archive mode (preserves permissions, timestamps, etc.)
        # -v: verbose
        # -z: compress during transfer
        # --progress: show progress
        # --delete: delete files on server that don't exist locally

        rsync -avz --progress --delete \
            "${ALBUMS_DIR}/${album}/low/" \
            "${NGINX_USER}@${NGINX_SERVER}:${NGINX_PATH}/${album}/low/"

        rsync -avz --progress --delete \
            "${ALBUMS_DIR}/${album}/full/" \
            "${NGINX_USER}@${NGINX_SERVER}:${NGINX_PATH}/${album}/full/"

        print_success "  ✓ Uploaded $album"
    done

    echo ""
    print_success "All photos uploaded to nginx server!"
    print_info "Photos are now accessible at: https://$NGINX_SERVER/[album-name]/low/[photo].webp"
}

###############################################################################
# Main Script Execution
###############################################################################

main() {
    echo ""
    print_info "=== Pi Kappa Phi Photo Upload Script ==="
    echo ""

    # Check for ffmpeg
    check_ffmpeg

    # Find uninitialized albums
    local album_count=0
    local album_array=()

    # Read albums into array, handling spaces in directory names
    while IFS= read -r album_dir; do
        if [ -n "$album_dir" ]; then
            album_array+=("$album_dir")
            ((album_count++))
        fi
    done < <(find_uninitialized_albums)

    if [ $album_count -eq 0 ]; then
        print_success "No uninitialized albums found. All albums are ready!"
        echo ""

        # Regenerate albums.json in case manually edited
        generate_albums_manifest
        echo ""

        # Still offer deployment options
        deploy_to_nginx
        echo ""
        deploy_to_git
        echo ""
        deploy_to_firebase

        exit 0
    fi

    print_info "Found $album_count uninitialized album(s)"
    echo ""

    # Process each album
    for album in "${album_array[@]}"; do
        process_album "$album"
    done

    # Summary
    print_success "=== Processing Complete ==="
    print_info "Processed $album_count album(s)"
    echo ""

    # Generate albums manifest
    generate_albums_manifest
    echo ""

    # Deployment
    deploy_to_nginx
    echo ""
    deploy_to_git
    echo ""
    deploy_to_firebase

    echo ""
    print_success "All done! 🎉"
    echo ""
}

# Run main function
main
