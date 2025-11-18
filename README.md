# Digital Signage Management System

A lightweight, file-based digital signage system built with Flask for managing content across multiple TV displays on Debian Linux.

## Features

- Web interface for uploading and managing PowerPoint presentations
- Automatic conversion of PowerPoint slides to JPG images
- Support for manual image uploads (JPG, PNG, GIF)
- Per-slide duration configuration
- Drag-and-drop slide reordering
- Multi-TV support (up to 4 displays)
- Fullscreen slideshow display with auto-refresh
- Simple session-based authentication
- No database required - filesystem only
- HTTPS ready with Let's Encrypt support

## System Requirements

- Debian 11+ or Ubuntu 20.04+ (or similar Linux distribution)
- Python 3.8+
- Nginx (for production deployment)
- Chromium browser (for display clients)

---

## Installation

### Clone the Repository

```bash
cd /opt
sudo git clone https://github.com/ruapotato/DigitalSignage.git digital_signage
cd digital_signage
```

### Quick Setup (Development/Testing)

```bash
# Run the automated setup script
./setup.sh

# Activate virtual environment
source pyenv/bin/activate

# Start the development server
python main.py
```

The application will be available at `http://localhost:5000`

**Default login credentials:** `admin` / `changeme123` (change these in `creds.txt`!)

---

## Production Deployment

### Pre-Deployment Checklist

- [ ] Debian 11+ server with root access
- [ ] Domain name pointing to your server
- [ ] Firewall configured (ports 80, 443)
- [ ] At least 10GB free disk space
- [ ] Updated system packages

### Step 1: Update System and Install Dependencies

```bash
sudo apt update
sudo apt upgrade -y

sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    nginx \
    certbot \
    python3-certbot-nginx \
    git \
    ufw
```

### Step 2: Clone and Deploy Application

```bash
# Clone repository
cd /opt
sudo git clone https://github.com/ruapotato/DigitalSignage.git digital_signage
cd digital_signage

# Set ownership
sudo chown -R www-data:www-data /opt/digital_signage

# Set permissions
sudo chmod 755 /opt/digital_signage
sudo chmod +x /opt/digital_signage/kiosk-startup.sh
```

### Step 3: Configure Credentials

```bash
# Generate a strong password
STRONG_PASSWORD=$(openssl rand -base64 32)

# Update credentials file
echo "admin:${STRONG_PASSWORD}" | sudo tee /opt/digital_signage/creds.txt
sudo chown www-data:www-data /opt/digital_signage/creds.txt
sudo chmod 600 /opt/digital_signage/creds.txt

# Save password securely
echo "Admin password: ${STRONG_PASSWORD}" | sudo tee /root/digital-signage-password.txt
sudo chmod 600 /root/digital-signage-password.txt

echo "Password saved to /root/digital-signage-password.txt"
```

### Step 4: Set Up Python Environment

```bash
cd /opt/digital_signage

# Create virtual environment as www-data
sudo -u www-data python3 -m venv pyenv

# Install dependencies
sudo -u www-data pyenv/bin/pip install --upgrade pip
sudo -u www-data pyenv/bin/pip install -r requirements.txt
```

### Step 5: Configure Systemd Service

```bash
# Copy service file
sudo cp digital-signage.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable and start service
sudo systemctl enable digital-signage
sudo systemctl start digital-signage

# Check status
sudo systemctl status digital-signage

# Verify service is running
curl http://localhost:5000
```

### Step 6: Configure Nginx (Before SSL)

```bash
# Copy and edit nginx configuration
sudo cp nginx-site.conf /tmp/nginx-site.conf

# Replace 'your-domain.com' with your actual domain
sudo sed -i 's/your-domain.com/youractual.domain.com/g' /tmp/nginx-site.conf

# Temporarily comment out HTTPS server block for initial setup
sudo nano /tmp/nginx-site.conf
# Comment out the entire second server block (listen 443 ssl http2)
# Keep only the HTTP (port 80) server block

# Install configuration
sudo cp /tmp/nginx-site.conf /etc/nginx/sites-available/digital-signage

# Enable site
sudo ln -s /etc/nginx/sites-available/digital-signage /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

### Step 7: Obtain SSL Certificate with Let's Encrypt

```bash
# Run certbot - it will automatically configure nginx
sudo certbot --nginx -d youractual.domain.com

# Follow the prompts
# Certbot will automatically configure nginx for HTTPS

# Test auto-renewal
sudo certbot renew --dry-run
```

### Step 8: Restore Full Nginx Configuration

After certbot succeeds:

```bash
# Use the original configuration with SSL paths
sudo cp nginx-site.conf /tmp/nginx-final.conf

# Update domain
sudo sed -i 's/your-domain.com/youractual.domain.com/g' /tmp/nginx-final.conf

# Install final configuration
sudo cp /tmp/nginx-final.conf /etc/nginx/sites-available/digital-signage

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

### Step 9: Configure Firewall

```bash
# Enable UFW
sudo ufw --force enable

# Allow SSH (important!)
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Check status
sudo ufw status
```

### Step 10: Create Slides Directories

```bash
# Create initial TV directories
sudo -u www-data mkdir -p /opt/digital_signage/slides/TV_001
sudo -u www-data mkdir -p /opt/digital_signage/slides/TV_002
echo "[]" | sudo -u www-data tee /opt/digital_signage/slides/TV_001/config.json
echo "[]" | sudo -u www-data tee /opt/digital_signage/slides/TV_002/config.json
```

### Verify Deployment

1. Access `https://yourdomain.com` - should redirect to login
2. Login with credentials from `/root/digital-signage-password.txt`
3. Create a test TV
4. Upload a test image
5. Access display URL from another device
6. Verify slideshow plays correctly

---

## TV Display Setup (Kiosk Mode)

### On Each Display Client (NUC, Raspberry Pi, etc.)

#### 1. Install Required Packages

```bash
sudo apt update
sudo apt install -y \
    chromium \
    chromium-browser \
    unclutter \
    x11-xserver-utils \
    xserver-xorg \
    xinit \
    git
```

#### 2. Get Kiosk Script

```bash
# Clone repository to get kiosk script
cd ~
git clone https://github.com/ruapotato/DigitalSignage.git
cp DigitalSignage/kiosk-startup.sh ~/kiosk-startup.sh
chmod +x ~/kiosk-startup.sh
```

#### 3. Configure Kiosk Script

```bash
# Edit configuration
nano ~/kiosk-startup.sh

# Update these variables:
# TV_ID="TV_001"  # Change to TV_001, TV_002, TV_003, or TV_004
# SERVER_URL="https://youractual.domain.com"
```

#### 4. Test Kiosk Mode

```bash
# Test manually first
./kiosk-startup.sh
```

Press `Alt+F4` or `Ctrl+W` to exit kiosk mode for testing.

#### 5. Auto-Start on Boot (Method 1: Desktop Autostart)

```bash
mkdir -p ~/.config/autostart

cat > ~/.config/autostart/digital-signage.desktop << EOF
[Desktop Entry]
Type=Application
Name=Digital Signage Kiosk
Exec=/home/$USER/kiosk-startup.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
```

#### 6. Auto-Start on Boot (Method 2: Systemd User Service)

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/digital-signage-kiosk.service << EOF
[Unit]
Description=Digital Signage Kiosk Display
After=graphical.target

[Service]
Type=simple
Environment=DISPLAY=:0
ExecStart=/home/$USER/kiosk-startup.sh
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

# Enable and start service
systemctl --user enable digital-signage-kiosk
systemctl --user start digital-signage-kiosk
```

#### 7. Disable Screen Blanking

```bash
# Create X11 configuration
sudo mkdir -p /etc/X11/xorg.conf.d

sudo tee /etc/X11/xorg.conf.d/10-monitor.conf << EOF
Section "ServerFlags"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection

Section "Extensions"
    Option "DPMS" "Disable"
EndSection
EOF
```

#### 8. Auto-Login (Optional)

For LightDM:
```bash
sudo nano /etc/lightdm/lightdm.conf
```

Add or modify:
```ini
[Seat:*]
autologin-user=your-username
autologin-user-timeout=0
```

For GDM:
```bash
sudo nano /etc/gdm3/custom.conf
```

Add:
```ini
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=your-username
```

---

## Usage Guide

### Accessing the Dashboard

Navigate to `https://yourdomain.com` and login with your credentials.

### Creating a New TV

1. Click "Add New TV" on the dashboard
2. A new TV (TV_003, TV_004, etc.) will be created
3. Click "Manage" to add content

### Managing TV Content

1. Click on a TV card to access its management page
2. **Upload PowerPoint**: Drag .pptx file or click to browse (slides extracted automatically)
3. **Upload Images**: Drag image files (JPG, PNG, GIF) or click to browse
4. **Set Duration**: Adjust seconds for each slide (default: 5 seconds)
5. **Reorder Slides**: Drag slides up/down using the grip icon
6. **Delete Slides**: Click the trash icon to remove a slide
7. **Preview**: Click "Preview Display" to see fullscreen view

### Display URLs

Each TV has a unique display URL (no authentication required):
- `https://yourdomain.com/display/TV_001`
- `https://yourdomain.com/display/TV_002`
- `https://yourdomain.com/display/TV_003`
- `https://yourdomain.com/display/TV_004`

These URLs automatically refresh content every 30 seconds.

---

## File Structure

```
digital_signage/
├── main.py                 # Flask application
├── requirements.txt        # Python dependencies
├── creds.txt              # Login credentials (username:password)
├── setup.sh               # Quick setup script
├── digital-signage.service # Systemd service file
├── nginx-site.conf        # Nginx configuration
├── kiosk-startup.sh       # TV kiosk startup script
├── templates/             # HTML templates
│   ├── login.html
│   ├── dashboard.html
│   ├── tv_management.html
│   └── display.html
├── static/                # CSS/JS (currently using CDN)
├── pyenv/                 # Virtual environment (gitignored)
└── slides/                # Slide storage (gitignored)
    ├── TV_001/
    │   ├── config.json    # [{"filename": "1.jpg", "duration_seconds": 5}, ...]
    │   ├── 1.jpg
    │   └── 2.jpg
    └── TV_002/
        └── ...
```

---

## API Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/` | GET | No | Redirect to login or dashboard |
| `/login` | GET/POST | No | Login page |
| `/logout` | GET | Yes | Logout |
| `/dashboard` | GET | Yes | Main dashboard |
| `/tv/<tv_id>` | GET | Yes | TV management page |
| `/display/<tv_id>` | GET | No | Fullscreen slideshow |
| `/api/check/<tv_id>` | GET | No | Get config JSON |
| `/api/upload_pptx/<tv_id>` | POST | Yes | Upload PowerPoint |
| `/api/upload_image/<tv_id>` | POST | Yes | Upload image |
| `/api/reorder/<tv_id>` | POST | Yes | Reorder slides |
| `/api/update_duration/<tv_id>` | POST | Yes | Update slide duration |
| `/api/delete_slide/<tv_id>` | POST | Yes | Delete slide |
| `/api/create_tv` | POST | Yes | Create new TV |
| `/slides/<tv_id>/<filename>` | GET | No | Serve slide image |

---

## Maintenance

### View Service Logs

```bash
# Real-time logs
sudo journalctl -u digital-signage -f

# Last 100 lines
sudo journalctl -u digital-signage -n 100
```

### Restart Service

```bash
sudo systemctl restart digital-signage
```

### Update Application

```bash
# Stop service
sudo systemctl stop digital-signage

# Pull latest changes
cd /opt/digital_signage
sudo -u www-data git pull

# Update dependencies
sudo -u www-data pyenv/bin/pip install -r requirements.txt --upgrade

# Restart service
sudo systemctl start digital-signage
```

### Backup Slides and Configuration

```bash
# Create backup
tar -czf digital-signage-backup-$(date +%Y%m%d).tar.gz \
  /opt/digital_signage/slides \
  /opt/digital_signage/creds.txt

# Automated backup script
sudo tee /opt/digital_signage/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/digital-signage"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/slides-$DATE.tar.gz -C /opt/digital_signage slides
cp /opt/digital_signage/creds.txt $BACKUP_DIR/creds-$DATE.txt
ls -t $BACKUP_DIR/slides-*.tar.gz | tail -n +8 | xargs -r rm
echo "Backup completed: $DATE"
EOF

sudo chmod +x /opt/digital_signage/backup.sh

# Schedule daily backups at 2 AM
(sudo crontab -l 2>/dev/null; echo "0 2 * * * /opt/digital_signage/backup.sh") | sudo crontab -
```

---

## Troubleshooting

### Service Won't Start

```bash
# Check logs
sudo journalctl -u digital-signage -n 50

# Check if port 5000 is in use
sudo netstat -tlnp | grep 5000

# Check permissions
sudo ls -la /opt/digital_signage

# Restart service
sudo systemctl restart digital-signage
```

### Display Not Updating

1. Check network connectivity from display client
2. Verify URL is accessible: `curl https://yourdomain.com/display/TV_001`
3. Open browser console (F12) to check for JavaScript errors
4. Verify slides exist in management interface
5. Check config.json formatting: `cat /opt/digital_signage/slides/TV_001/config.json`

### Upload Fails

```bash
# Check nginx max upload size
sudo nano /etc/nginx/sites-available/digital-signage
# Ensure: client_max_body_size 100M;

# Check file permissions
sudo chown -R www-data:www-data /opt/digital_signage/slides

# Check disk space
df -h
```

### Kiosk Mode Issues

```bash
# Check if Chromium is running
ps aux | grep chromium

# Kill and restart
pkill chromium
./kiosk-startup.sh

# Check display environment variable
echo $DISPLAY  # Should be :0

# Test URL manually
chromium https://yourdomain.com/display/TV_001
```

### SSL Certificate Issues

```bash
# Check certificate status
sudo certbot certificates

# Renew manually
sudo certbot renew

# Test renewal
sudo certbot renew --dry-run
```

### Nginx Errors

```bash
# Test configuration
sudo nginx -t

# Check error logs
sudo tail -f /var/log/nginx/error.log

# Verify backend is running
curl http://localhost:5000
```

---

## PowerPoint Conversion Notes

The current implementation extracts embedded images from PowerPoint slides. For best results:

1. **Use PowerPoint with image backgrounds** - Slides with images work best
2. **Export slides as images first** - Alternative approach for complex slides
3. **Install LibreOffice for advanced conversion**:

```bash
sudo apt install -y libreoffice python3-uno
```

Then modify `main.py` at line 100 to use LibreOffice conversion:
```python
import subprocess
subprocess.run(['libreoffice', '--headless', '--convert-to', 'pdf', pptx_file])
# Then use pdf2image to convert PDF pages to JPG
```

---

## Security Considerations

1. **Change default credentials** in `creds.txt` immediately
2. **Use HTTPS** in production (configured via Let's Encrypt)
3. **Firewall**: Only expose ports 22 (SSH), 80 (HTTP), 443 (HTTPS)
4. **File permissions**: Slides directory writable only by www-data
5. **Regular updates**: Keep system and packages updated
6. **Limit access**: Consider restricting admin interface to internal network only (nginx allow/deny rules)

### Optional: Restrict Admin Access to Internal Network

Edit `/etc/nginx/sites-available/digital-signage`:

```nginx
location / {
    allow 192.168.1.0/24;  # Your internal network
    deny all;
    proxy_pass http://127.0.0.1:5000;
}

location /display/ {
    # Keep display URLs public
    proxy_pass http://127.0.0.1:5000;
}
```

---

## Performance Tips

### Nginx Caching

Add to nginx server block:

```nginx
location ~* \.(jpg|jpeg|png|gif)$ {
    expires 1h;
    add_header Cache-Control "public, immutable";
}
```

### Reduce Chromium Memory Usage

In `kiosk-startup.sh`, add these flags to chromium command:
```bash
--disk-cache-size=52428800 \
--media-cache-size=52428800
```

---

## Technical Details

- **Framework**: Flask 3.0 (development server for single-user deployment)
- **Image Processing**: Pillow (1920x1080 with aspect ratio preservation)
- **PowerPoint Parsing**: python-pptx
- **Storage**: Filesystem only (JSON config files, no database)
- **UI**: Bootstrap 5 with custom JavaScript
- **Auto-refresh**: Display pages check for updates every 30 seconds
- **Max TVs**: 4 displays (configurable in main.py)
- **Target Resolution**: 1920x1080 (Full HD)

---

## License

This is a custom implementation for small-scale digital signage deployment.

## Support

For issues or questions:
- Check the troubleshooting section above
- Review system logs: `sudo journalctl -u digital-signage -n 100`
- Check GitHub issues: https://github.com/ruapotato/DigitalSignage/issues

---

## Quick Reference

### Essential Commands

```bash
# Server
sudo systemctl status digital-signage    # Check service status
sudo systemctl restart digital-signage   # Restart service
sudo journalctl -u digital-signage -f    # View logs
sudo nginx -t                            # Test nginx config
sudo certbot renew                       # Renew SSL certificate

# Display Client
./kiosk-startup.sh TV_001               # Start kiosk mode
pkill chromium                          # Stop kiosk mode
```

### Important URLs

- Management: `https://yourdomain.com/dashboard`
- Display TV_001: `https://yourdomain.com/display/TV_001`
- API Check: `https://yourdomain.com/api/check/TV_001`

### Important Files

- Credentials: `/opt/digital_signage/creds.txt`
- Service: `/etc/systemd/system/digital-signage.service`
- Nginx Config: `/etc/nginx/sites-available/digital-signage`
- Logs: `journalctl -u digital-signage`
- Slides: `/opt/digital_signage/slides/`
