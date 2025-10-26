# Nginx Server Setup Complete ✅

## Summary

The nginx server has been successfully configured on this server to host photos for the Pi Kappa Phi photo gallery at `pikapp-photos.ct-42210.com`.

## What Was Configured

### 1. System User
- Created `pikapp-photos` system user (uid: 996, gid: 988)
- User owns all photo directories and runs nginx process

### 2. Directory Structure
- Photo root: `/var/www/pikapp-photos/`
- Owned by: `pikapp-photos:pikapp-photos`
- Permissions: 755

### 3. Nginx Installation
- Installed nginx 1.24.0
- Configured to listen on port 8081 (to coexist with Apache on port 80)
- Running as `pikapp-photos` user

### 4. Nginx Configuration Files (in git repo)
- `/server/nginx/nginx.conf` - Main nginx config
- `/server/nginx/pikapp-photos.conf` - Virtual host config
- `/server/nginx/deploy.sh` - Deployment script
- `/server/README.md` - Documentation

### 5. Features Enabled
- ✅ CORS headers for Firebase site (`pikapp-photos.web.app`)
- ✅ Gzip compression for images
- ✅ Browser caching (1 year for immutable photos)
- ✅ Security headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)
- ✅ Access and error logging
- ✅ Server tokens disabled
- ✅ Directory indexing disabled

### 6. Upload Script Updated
- Added `deploy_to_nginx()` function to `upload.sh`
- Uses rsync over SSH to upload photos
- Target: `pikapp-photos@pikapp-photos.ct-42210.com:/var/www/pikapp-photos/`

### 7. Documentation Updated
- Updated `outline.txt` with complete nginx server specifications
- Updated `.gitignore` to exclude photo directories from git
- Created server documentation in `/server/README.md`

## Server Status

```
✅ Nginx installed: nginx/1.24.0
✅ Nginx running: Active (running)
✅ Listening on: 0.0.0.0:8081
✅ CORS headers: Configured
✅ Photo directory: Created
```

## Next Steps

### 1. Cloudflare Tunnel - ✅ CONFIGURED
Cloudflare Tunnel has been configured and is running:

- ✅ Tunnel service: `ct-42210-server` (running)
- ✅ Route configured: `pikapp-photos.ct-42210.com` → `localhost:8081`
- ✅ Config file: `/etc/cloudflared/config.yml` (also backed up in git repo)

The Cloudflare Tunnel is already active and routing traffic. No additional configuration needed!

### 2. SSH Key Authentication - ✅ CONFIGURED
SSH authentication is already set up:

- ✅ Using existing root SSH key: `njt-hpe-proliant`
- ✅ Upload target: `root@pikapp-photos.ct-42210.com`

The upload script will use the existing root user SSH key for photo uploads. No additional setup needed!

### 3. Test Photo Upload
After SSH keys are configured, test the upload:

```bash
# Create a test album
mkdir -p public/albums/test_album
# Add some test images to public/albums/test_album/

# Run upload script
./upload.sh
```

### 4. Test Photo Access
Once photos are uploaded and Cloudflare is configured:

```bash
# Test from local server
curl -I http://localhost:8081/[album-name]/low/[photo].webp

# Test from public URL (after Cloudflare setup)
curl -I https://pikapp-photos.ct-42210.com/[album-name]/low/[photo].webp
```

## Maintenance

### Updating Nginx Configuration
After making changes to config files in the git repo:

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

## File Locations

- **Server configs (git repo)**: `/root/pikapp-photos/server/`
- **System nginx config**: `/etc/nginx/nginx.conf`
- **Site config**: `/etc/nginx/sites-available/pikapp-photos.conf`
- **Photo storage**: `/var/www/pikapp-photos/`
- **Logs**: `/var/log/nginx/`

## Questions?

Refer to `/root/pikapp-photos/server/README.md` for detailed documentation.
