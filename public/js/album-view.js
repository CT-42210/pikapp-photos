/**
 * Album View Logic
 * Handles loading and displaying photos for a specific album
 */

// Album state
let currentAlbum = null;
let albumPhotos = [];

/**
 * Initialize the album view page
 */
async function initAlbumView() {
    try {
        // Get album name from URL query parameter
        const urlParams = new URLSearchParams(window.location.search);
        const albumFolder = urlParams.get('album');

        if (!albumFolder) {
            displayError('No album specified in URL');
            return;
        }

        // Load album data and photos
        await loadAlbum(albumFolder);
        await loadPhotos(albumFolder);

        // Render album header and photo grid
        renderAlbumHeader();
        renderPhotoGrid();

    } catch (error) {
        console.error('Error initializing album view:', error);
        displayError(`Failed to load album: ${error.message}`);
    }
}

/**
 * Load album metadata from data.json
 * @param {string} albumFolder - Album folder name
 */
async function loadAlbum(albumFolder) {
    try {
        const response = await fetch(`albums/${albumFolder}/data.json`);

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        currentAlbum = await response.json();
        currentAlbum.folderName = albumFolder;

    } catch (error) {
        console.error('Error loading album data:', error);
        throw new Error(`Could not load album data: ${error.message}`);
    }
}

/**
 * Load photos from the album data.json
 * @param {string} albumFolder - Album folder name
 */
async function loadPhotos(albumFolder) {
    try {
        // Photos are already in currentAlbum.photos array from data.json
        if (!currentAlbum.photos || currentAlbum.photos.length === 0) {
            throw new Error('No photos found in album data');
        }

        // Handle both old format (strings) and new format (objects with webp and ext)
        albumPhotos = currentAlbum.photos.map(photo => {
            // New format: {webp: "photo.webp", ext: "jpg"}
            if (typeof photo === 'object' && photo.webp) {
                const baseName = photo.webp.replace('.webp', '');
                return {
                    thumbnail: `albums/${albumFolder}/low/${photo.webp}`,
                    lightbox: `albums/${albumFolder}/low/${photo.webp}`,  // Same as thumbnail - just expanded
                    original: `albums/${albumFolder}/full/${baseName}.${photo.ext}`  // For downloads
                };
            }
            // Old format: just filename string (backward compatibility)
            else {
                return {
                    thumbnail: `albums/${albumFolder}/low/${photo}`,
                    lightbox: `albums/${albumFolder}/low/${photo}`,
                    original: `albums/${albumFolder}/full/${photo}`
                };
            }
        });

    } catch (error) {
        console.error('Error loading photos:', error);
        throw new Error(`Could not load photos: ${error.message}`);
    }
}

/**
 * Get the original file extension (helper function)
 * Assumes original photos are JPG if not specified
 * @param {string} filename - WebP filename
 * @returns {string} Original extension
 */
function getOriginalExtension(filename) {
    // For now, assume original photos in /full keep their original extensions
    // The upload script will handle this, but we'll check both possibilities
    return filename.substring(filename.lastIndexOf('.'));
}

/**
 * Render the album header with name and info
 */
function renderAlbumHeader() {
    const nameElement = document.getElementById('album-name');
    const infoElement = document.getElementById('album-info');

    if (!nameElement || !infoElement) {
        console.error('Album header elements not found');
        return;
    }

    nameElement.textContent = currentAlbum.name;

    // Format album info: photographer and date
    const date = new Date(currentAlbum.date);
    const formattedDate = date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });

    infoElement.textContent = `Photos by ${currentAlbum.photographer} • ${formattedDate}`;
}

/**
 * Render the photo grid with all photos
 */
function renderPhotoGrid() {
    const gridContainer = document.getElementById('photo-grid');

    if (!gridContainer) {
        console.error('Photo grid container not found');
        return;
    }

    // Clear any existing content
    gridContainer.innerHTML = '';

    if (albumPhotos.length === 0) {
        displayError('No photos found in this album');
        return;
    }

    // Create and append photo thumbnails
    albumPhotos.forEach((photo, index) => {
        const thumbnail = createPhotoThumbnail(photo, index);
        gridContainer.appendChild(thumbnail);
    });

    // Initialize lightbox after photos are rendered
    if (typeof window.initLightboxWhenReady === 'function') {
        window.initLightboxWhenReady();
    } else {
        console.error('window.initLightboxWhenReady is not a function!');
    }
}

/**
 * Create a photo thumbnail element
 * @param {Object} photo - Photo object with thumbnail and fullsize paths
 * @param {number} index - Photo index in the album
 * @returns {HTMLElement} Photo thumbnail element
 */
function createPhotoThumbnail(photo, index) {
    // Create thumbnail container
    const thumbnailDiv = document.createElement('a');
    thumbnailDiv.className = 'photo-thumbnail glightbox';
    thumbnailDiv.href = photo.lightbox;  // /low webp - just expanded in lightbox
    thumbnailDiv.setAttribute('data-gallery', 'album-gallery');

    // Store original URL for downloading
    if (photo.original) {
        thumbnailDiv.setAttribute('data-original', photo.original);
    }

    // Create thumbnail image
    const image = document.createElement('img');
    image.src = photo.thumbnail;
    image.alt = `${currentAlbum.name} - Photo ${index + 1}`;
    image.loading = 'lazy'; // Native lazy loading

    // Append image to thumbnail
    thumbnailDiv.appendChild(image);

    return thumbnailDiv;
}

/**
 * Display an error message to the user
 * @param {string} message - Error message to display
 */
function displayError(message) {
    const gridContainer = document.getElementById('photo-grid');

    if (gridContainer) {
        gridContainer.innerHTML = `
            <div class="error-message">
                ${message}
            </div>
        `;
    }

    // Also update header with error
    const nameElement = document.getElementById('album-name');
    if (nameElement) {
        nameElement.textContent = 'Error Loading Album';
    }

    console.error('Album error:', message);
}

/**
 * Display a loading state
 */
function displayLoading() {
    const gridContainer = document.getElementById('photo-grid');

    if (gridContainer) {
        gridContainer.innerHTML = `
            <div class="loading">
                Loading photos
            </div>
        `;
    }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAlbumView);
} else {
    // DOM already loaded
    initAlbumView();
}
