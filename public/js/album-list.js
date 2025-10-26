/**
 * Album List Logic
 * Handles loading and displaying album cards on the home page
 */

// Configuration: Photo server URL (nginx server)
const PHOTO_SERVER_URL = 'https://pikapp-photos.ct-42210.com';

// Album data cache
let albumsData = [];

/**
 * Initialize the album list page
 */
async function initAlbumList() {
    try {
        await loadAlbums();
        renderAlbumGrid();
    } catch (error) {
        displayError(`Failed to load albums: ${error.message}`);
    }
}

/**
 * Load all albums from the albums.json manifest
 * Firebase Hosting doesn't support directory listing, so we use a manifest file
 */
async function loadAlbums() {
    try {
        // Fetch the albums manifest
        const response = await fetch('albums.json');

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const manifest = await response.json();

        // Load JSON file for each album in the manifest
        const albumPromises = manifest.albums.map(async (albumName) => {
            try {
                const dataResponse = await fetch(`albums/${albumName}.json`);
                if (!dataResponse.ok) {
                    console.warn(`No JSON file found for album: ${albumName}`);
                    return null;
                }

                const albumData = await dataResponse.json();

                // Add folder name to album data for navigation
                albumData.folderName = albumName;

                return albumData;
            } catch (error) {
                console.warn(`Error loading album ${albumName}: ${error.message}`);
                return null;
            }
        });

        // Wait for all albums to load
        const results = await Promise.all(albumPromises);

        // Filter out failed loads and store valid albums
        albumsData = results.filter(album => album !== null);

        // Sort by date (newest first)
        albumsData.sort((a, b) => new Date(b.date) - new Date(a.date));

    } catch (error) {
        console.error('Error in loadAlbums:', error);
        throw error;
    }
}

/**
 * Render the album grid with all loaded albums
 */
function renderAlbumGrid() {
    const gridContainer = document.getElementById('album-grid');

    // Clear any existing content
    gridContainer.innerHTML = '';

    // If no albums, just show empty state (background, nav, footer)
    if (albumsData.length === 0) {
        // Per requirements: no special "no albums" messaging
        return;
    }

    // Create and append album cards
    albumsData.forEach(album => {
        const card = createAlbumCard(album);
        gridContainer.appendChild(card);
    });
}

/**
 * Create an album card element
 * @param {Object} album - Album data object with name, coverPhoto, folderName
 * @returns {HTMLElement} Album card element
 */
function createAlbumCard(album) {
    // Create card container
    const card = document.createElement('div');
    card.className = 'album-card';
    card.setAttribute('role', 'button');
    card.setAttribute('tabindex', '0');
    card.setAttribute('aria-label', `Open album: ${album.name}`);

    // Create cover image
    const image = document.createElement('img');
    image.className = 'album-card-image';
    image.src = `${PHOTO_SERVER_URL}/${album.folderName}/low/${album.coverPhoto}`;
    image.alt = album.name;
    image.loading = 'lazy'; // Native lazy loading

    // Create gradient overlay
    const overlay = document.createElement('div');
    overlay.className = 'album-card-overlay';

    // Create title
    const title = document.createElement('h2');
    title.className = 'album-card-title';
    title.textContent = album.name;

    // Assemble card
    card.appendChild(image);
    card.appendChild(overlay);
    card.appendChild(title);

    // Add click handler to navigate to album view
    card.addEventListener('click', () => {
        navigateToAlbum(album.folderName);
    });

    // Add keyboard navigation support
    card.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            navigateToAlbum(album.folderName);
        }
    });

    return card;
}

/**
 * Navigate to the album view page
 * @param {string} albumFolder - Album folder name
 */
function navigateToAlbum(albumFolder) {
    window.location.href = `album.html?album=${encodeURIComponent(albumFolder)}`;
}

/**
 * Display an error message to the user
 * @param {string} message - Error message to display
 */
function displayError(message) {
    const gridContainer = document.getElementById('album-grid');
    gridContainer.innerHTML = `
        <div class="error-message">
            ${message}
        </div>
    `;
}

/**
 * Display a loading state
 */
function displayLoading() {
    const gridContainer = document.getElementById('album-grid');
    gridContainer.innerHTML = `
        <div class="loading">
            Loading albums
        </div>
    `;
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAlbumList);
} else {
    // DOM already loaded
    initAlbumList();
}
