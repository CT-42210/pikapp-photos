# Nginx Server Configuration for pikapp-photos

This directory contains the nginx server configuration files for hosting photos at `pikapp-photos.ct-42210.com`.

## Architecture Overview

- **Server User**: `pikapp-photos` (system user)
- **Photo Storage**: `/var/www/pikapp-photos/`
- **Nginx Port**: `8081` (to coexist with Apache on port 80)
- **Cloudflare Routing**: Routes `pikapp-photos.ct-42210.com` to port 8081

## Directory Structure

```
server/
├── nginx/
│   ├── nginx.conf              # Main nginx configuration
│   ├── pikapp-photos.conf      # Site-specific virtual host config
│   └── deploy.sh               # Deployment script
└── README.md                   # This file
```

## Initial Server Setup

### 1. Create pikapp-photos User

```bash
sudo useradd -r -s /bin/bash -m -d /home/pikapp-photos pikapp-photos
```

### 2. Create Photo Directory

```bash
sudo mkdir -p /var/www/pikapp-photos
sudo chown pikapp-photos:pikapp-photos /var/www/pikapp-photos
sudo chmod 755 /var/www/pikapp-photos
```

### 3. Install Nginx

```bash
sudo apt-get update
sudo apt-get install -y nginx
```

### 4. Deploy Configuration

```bash
cd /root/pikapp-photos/server/nginx
sudo bash deploy.sh
```

The `deploy.sh` script will:
- Copy `nginx.conf` to `/etc/nginx/nginx.conf`
- Copy `pikapp-photos.conf` to `/etc/nginx/sites-available/`
- Create symlink in `/etc/nginx/sites-enabled/`
- Test nginx configuration
- Reload nginx

### 5. Configure Cloudflare Tunnel

Cloudflare Tunnel is already configured on this server. The tunnel configuration has been updated to include the pikapp-photos subdomain:

```bash
# The configuration is stored in:
# - System: /etc/cloudflared/config.yml
# - Git repo: /root/pikapp-photos/server/cloudflared-config.yml

# To update the tunnel configuration:
sudo cp /root/pikapp-photos/server/cloudflared-config.yml /etc/cloudflared/config.yml
sudo cloudflared --config /etc/cloudflared/config.yml tunnel ingress validate
sudo systemctl restart cloudflared
```

The tunnel automatically routes `pikapp-photos.ct-42210.com` → `localhost:8081`

## Photo Upload Workflow

Photos are uploaded via the `upload.sh` script in the project root:

```bash
# From your local machine
./upload.sh
```

This script will:
1. Process photos locally (create webP thumbnails and copy originals)
2. Upload photos to nginx server via rsync/scp:
   ```bash
   rsync -avz --progress /public/albums/[album-name]/low/ root@pikapp-photos.ct-42210.com:/var/www/pikapp-photos/[album-name]/low/
   rsync -avz --progress /public/albums/[album-name]/full/ root@pikapp-photos.ct-42210.com:/var/www/pikapp-photos/[album-name]/full/
   ```

**Note:** The upload uses the root SSH user with the existing njt-hpe-proliant SSH key for authentication.

## File Permissions

All files in `/var/www/pikapp-photos/` should be owned by `pikapp-photos:pikapp-photos` with `644` permissions for files and `755` for directories.

## CORS Configuration

The nginx configuration includes CORS headers to allow the Firebase-hosted website (`pikapp-photos.web.app`) to fetch photos:

- `Access-Control-Allow-Origin: https://pikapp-photos.web.app`
- `Access-Control-Allow-Methods: GET, OPTIONS`
- `Access-Control-Allow-Headers: *`

## Caching

Photos are cached for 1 year (`Cache-Control: public, immutable`) since they are immutable content.

## Logs

- Access log: `/var/log/nginx/pikapp-photos-access.log`
- Error log: `/var/log/nginx/pikapp-photos-error.log`

## Testing

After deployment, test the configuration:

```bash
# Test nginx config syntax
sudo nginx -t

# Check if nginx is listening on port 8081
sudo netstat -tlnp | grep 8081

# Test photo access (after uploading photos)
curl -I http://localhost:8081/[album-name]/low/photo.webp
```

## Maintenance

### Reload Configuration

After making changes to config files:

```bash
cd /root/pikapp-photos/server/nginx
sudo bash deploy.sh
```

### View Logs

```bash
# Access log
sudo tail -f /var/log/nginx/pikapp-photos-access.log

# Error log
sudo tail -f /var/log/nginx/pikapp-photos-error.log
```

### Restart Nginx

```bash
sudo systemctl restart nginx
```

## Security Notes

- Server runs as non-root user `pikapp-photos`
- Directory indexing is disabled
- Hidden files are denied
- Server tokens are disabled to hide nginx version
- Only TLS 1.2 and 1.3 are enabled
