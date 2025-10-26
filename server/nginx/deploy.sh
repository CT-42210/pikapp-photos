#!/bin/bash

# Nginx Deployment Script for pikapp-photos
# This script deploys the nginx configuration from the git repo to the system

set -e  # Exit on error

echo "======================================"
echo "Nginx Configuration Deployment"
echo "======================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Step 1: Validating configuration files..."
if [ ! -f "$SCRIPT_DIR/nginx.conf" ]; then
    echo "ERROR: nginx.conf not found in $SCRIPT_DIR"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/pikapp-photos.conf" ]; then
    echo "ERROR: pikapp-photos.conf not found in $SCRIPT_DIR"
    exit 1
fi

echo "✓ Configuration files found"
echo ""

echo "Step 2: Backing up existing nginx configuration..."
if [ -f /etc/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)
    echo "✓ Backed up /etc/nginx/nginx.conf"
fi

if [ -f /etc/nginx/sites-available/pikapp-photos.conf ]; then
    cp /etc/nginx/sites-available/pikapp-photos.conf /etc/nginx/sites-available/pikapp-photos.conf.backup.$(date +%Y%m%d_%H%M%S)
    echo "✓ Backed up existing pikapp-photos.conf"
fi
echo ""

echo "Step 3: Copying configuration files..."
cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/nginx.conf
echo "✓ Copied nginx.conf to /etc/nginx/"

mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

cp "$SCRIPT_DIR/pikapp-photos.conf" /etc/nginx/sites-available/pikapp-photos.conf
echo "✓ Copied pikapp-photos.conf to /etc/nginx/sites-available/"
echo ""

echo "Step 4: Creating symbolic link..."
if [ -L /etc/nginx/sites-enabled/pikapp-photos.conf ]; then
    rm /etc/nginx/sites-enabled/pikapp-photos.conf
fi

ln -s /etc/nginx/sites-available/pikapp-photos.conf /etc/nginx/sites-enabled/pikapp-photos.conf
echo "✓ Created symlink in /etc/nginx/sites-enabled/"
echo ""

echo "Step 5: Testing nginx configuration..."
if nginx -t; then
    echo "✓ Nginx configuration is valid"
else
    echo "ERROR: Nginx configuration test failed!"
    echo "Rolling back changes..."
    if [ -f /etc/nginx/nginx.conf.backup.* ]; then
        LATEST_BACKUP=$(ls -t /etc/nginx/nginx.conf.backup.* | head -1)
        cp "$LATEST_BACKUP" /etc/nginx/nginx.conf
    fi
    exit 1
fi
echo ""

echo "Step 6: Reloading nginx..."
if systemctl is-active --quiet nginx; then
    systemctl reload nginx
    echo "✓ Nginx reloaded"
else
    systemctl start nginx
    echo "✓ Nginx started"
fi
echo ""

echo "======================================"
echo "Deployment Complete!"
echo "======================================"
echo ""
echo "Nginx is now configured and running on port 8081"
echo ""
echo "Next steps:"
echo "1. Configure Cloudflare to route pikapp-photos.ct-42210.com to port 8081"
echo "2. Upload photos using the upload.sh script"
echo "3. Test photo access: curl -I http://localhost:8081/"
echo ""
echo "View logs:"
echo "  Access: sudo tail -f /var/log/nginx/pikapp-photos-access.log"
echo "  Error:  sudo tail -f /var/log/nginx/pikapp-photos-error.log"
