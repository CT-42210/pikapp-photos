/**
 * Lightbox Integration
 * Handles GLightbox initialization and download/share functionality
 */

// GLightbox instance
let lightbox = null;

/**
 * Initialize GLightbox with custom configuration
 */
function initLightbox() {
    // Wait for GLightbox to be available
    if (typeof GLightbox === 'undefined') {
        console.error('GLightbox library not loaded');
        return;
    }

    // Check if there are any elements to attach to
    const elements = document.querySelectorAll('.glightbox');

    if (elements.length === 0) {
        console.warn('No .glightbox elements found - cannot initialize');
        return;
    }

    // Destroy existing instance if any
    if (lightbox) {
        try {
            lightbox.destroy();
        } catch (e) {
            console.warn('Error destroying previous lightbox instance:', e);
        }
    }

    // Initialize GLightbox
    lightbox = GLightbox({
        touchNavigation: true,
        loop: true,
        closeOnOutsideClick: true,
        keyboardNavigation: true
    });

    // Add custom buttons after slide opens
    lightbox.on('slide_changed', ({ prev, current }) => {
        // Give the slide a moment to fully render
        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                addDownloadShareButtons(current);
            });
        });
    });

    lightbox.on('open', () => {
        // Remove focus from trigger element to fix aria-hidden warning
        if (document.activeElement) {
            document.activeElement.blur();
        }

        const currentSlide = lightbox.getActiveSlide();
        addDownloadShareButtons(currentSlide);
    });

    lightbox.on('close', () => {
        // Remove buttons when lightbox closes
        const existingControls = document.querySelector('.download-share-controls');
        if (existingControls) {
            existingControls.remove();
        }
    });
}

/**
 * Add download and share buttons to the current lightbox slide
 * @param {Object} slide - Current GLightbox slide object
 */
function addDownloadShareButtons(slide) {
    if (!slide || !slide.slideNode) {
        return;
    }

    const slideElement = slide.slideNode;
    const innerContainer = slideElement.querySelector('.ginner-container');

    if (!innerContainer) {
        return;
    }

    // Remove any existing buttons first (they're in document.body, not slideElement)
    const existingControls = document.querySelector('.download-share-controls');
    if (existingControls) {
        existingControls.remove();
    }

    // Get the original image URL for downloading
    // Use slide index to look up the correct gallery element
    let originalUrl = null;
    if (typeof slide.index !== 'undefined') {
        const galleryElements = document.querySelectorAll('.glightbox[data-gallery="album-gallery"]');
        if (galleryElements[slide.index]) {
            originalUrl = galleryElements[slide.index].getAttribute('data-original');
        }
    }

    // Fallback: try from slide.trigger
    if (!originalUrl && slide.trigger) {
        originalUrl = slide.trigger.getAttribute('data-original');
    }

    const displayUrl = slide.slideConfig ? slide.slideConfig.href : '';
    const downloadUrl = originalUrl || displayUrl;

    // Create button container
    const controlsDiv = document.createElement('div');
    controlsDiv.className = 'download-share-controls';
    controlsDiv.style.cssText = `
        position: fixed;
        bottom: 80px;
        right: 20px;
        display: flex;
        gap: 12px;
        z-index: 9999999;
    `;

    // Check if Web Share API is available (primarily mobile)
    const canShare = navigator.share && isMobileDevice();

    if (canShare) {
        // Show share button on mobile (use original file)
        const shareButton = createShareButton(downloadUrl);
        controlsDiv.appendChild(shareButton);
    } else {
        // Show download button on desktop (use original file)
        const downloadButton = createDownloadButton(downloadUrl);
        controlsDiv.appendChild(downloadButton);
    }

    // Append controls to document.body so they stay visible during slide transitions
    document.body.appendChild(controlsDiv);
}

/**
 * Create a download button for desktop
 * @param {string} imageUrl - URL of the fullsize image
 * @returns {HTMLElement} Download button element
 */
function createDownloadButton(imageUrl) {
    const button = document.createElement('button');
    button.className = 'download-button';
    button.innerHTML = `
        <svg class="button-icon" viewBox="0 0 24 24">
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
            <polyline points="7 10 12 15 17 10"></polyline>
            <line x1="12" x2="12" y1="15" y2="3"></line>
        </svg>
        Download
    `;

    button.addEventListener('click', (e) => {
        e.stopPropagation();
        downloadImage(imageUrl);
    });

    return button;
}

/**
 * Create a share button for mobile
 * @param {string} imageUrl - URL of the fullsize image
 * @returns {HTMLElement} Share button element
 */
function createShareButton(imageUrl) {
    const button = document.createElement('button');
    button.className = 'share-button';
    button.innerHTML = `
        <svg class="button-icon" viewBox="0 0 24 24">
            <circle cx="18" cy="5" r="3"></circle>
            <circle cx="6" cy="12" r="3"></circle>
            <circle cx="18" cy="19" r="3"></circle>
            <line x1="8.59" x2="15.42" y1="13.51" y2="17.49"></line>
            <line x1="15.41" x2="8.59" y1="6.51" y2="10.49"></line>
        </svg>
        Share
    `;

    button.addEventListener('click', (e) => {
        e.stopPropagation();
        shareImage(imageUrl);
    });

    return button;
}

/**
 * Download an image to the user's device
 * @param {string} imageUrl - URL of the image to download
 */
async function downloadImage(imageUrl) {
    try {
        // Fetch the image as a blob
        const response = await fetch(imageUrl);
        if (!response.ok) {
            throw new Error(`Failed to fetch image: ${response.statusText}`);
        }

        const blob = await response.blob();

        // Extract filename from URL
        const filename = imageUrl.substring(imageUrl.lastIndexOf('/') + 1);

        // Create a temporary download link
        const downloadLink = document.createElement('a');
        downloadLink.href = URL.createObjectURL(blob);
        downloadLink.download = filename;
        document.body.appendChild(downloadLink);
        downloadLink.click();
        document.body.removeChild(downloadLink);

        // Clean up the object URL
        URL.revokeObjectURL(downloadLink.href);

    } catch (error) {
        console.error('Error downloading image:', error);
        alert(`Failed to download image: ${error.message}`);
    }
}

/**
 * Share an image using the Web Share API
 * @param {string} imageUrl - URL of the image to share
 */
async function shareImage(imageUrl) {
    try {
        // Fetch the image as a blob
        const response = await fetch(imageUrl);
        if (!response.ok) {
            throw new Error(`Failed to fetch image: ${response.statusText}`);
        }

        const blob = await response.blob();

        // Extract filename from URL
        const filename = imageUrl.substring(imageUrl.lastIndexOf('/') + 1);

        // Create a File object from the blob
        const file = new File([blob], filename, { type: blob.type });

        // Check if we can share files
        if (navigator.canShare && navigator.canShare({ files: [file] })) {
            await navigator.share({
                files: [file],
                title: currentAlbum ? currentAlbum.name : 'Photo',
                text: 'Check out this photo from Pi Kappa Phi'
            });
        } else {
            // Fallback to download if sharing is not supported
            downloadImage(imageUrl);
        }

    } catch (error) {
        // User cancelled the share or error occurred
        if (error.name !== 'AbortError') {
            console.error('Error sharing image:', error);
            // Fallback to download
            downloadImage(imageUrl);
        }
    }
}

/**
 * Detect if the user is on a mobile device
 * @returns {boolean} True if mobile device
 */
function isMobileDevice() {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ||
           (navigator.maxTouchPoints && navigator.maxTouchPoints > 2);
}

/**
 * Initialize lightbox - should be called after photos are rendered
 * This is called by album-view.js after the photo grid is populated
 */
function initLightboxWhenReady() {
    // Check if GLightbox is loaded
    if (typeof GLightbox === 'undefined') {
        console.error('GLightbox library not loaded');
        return;
    }

    // Use requestAnimationFrame to ensure DOM has rendered
    requestAnimationFrame(() => {
        initLightbox();
    });
}

// Export for use by album-view.js
window.initLightboxWhenReady = initLightboxWhenReady;
