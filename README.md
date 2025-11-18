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

## Quick Start

### 1. Installation

```bash
# Clone or copy the project to your server
cd /opt
sudo mkdir digital_signage
sudo chown $USER:$USER digital_signage
cd digital_signage

# Create virtual environment
python3 -m venv pyenv
source pyenv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configuration

Edit `creds.txt` to set your username and password:

```bash
nano creds.txt
# Change from: admin:changeme123
# To your own credentials
```

### 3. Run Development Server

```bash
source pyenv/bin/activate
python main.py
```

The application will be available at `http://localhost:5000`

Default login credentials: `admin` / `changeme123` (change these!)

## Production Deployment

### Step 1: Install System Dependencies

```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx python3-pip python3-venv
```

### Step 2: Set Up Application

```bash
# Move application to /opt
sudo cp -r /path/to/digital_signage /opt/
sudo chown -R www-data:www-data /opt/digital_signage
sudo chmod +x /opt/digital_signage/kiosk-startup.sh

# Install Python dependencies
cd /opt/digital_signage
sudo -u www-data python3 -m venv pyenv
sudo -u www-data pyenv/bin/pip install -r requirements.txt
```

### Step 3: Configure Systemd Service

```bash
# Copy systemd service file
sudo cp digital-signage.service /etc/systemd/system/

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable digital-signage
sudo systemctl start digital-signage

# Check status
sudo systemctl status digital-signage
```

### Step 4: Configure Nginx

```bash
# Edit nginx-site.conf and replace 'your-domain.com' with your actual domain
nano nginx-site.conf

# Copy nginx configuration
sudo cp nginx-site.conf /etc/nginx/sites-available/digital-signage

# Enable site
sudo ln -s /etc/nginx/sites-available/digital-signage /etc/nginx/sites-enabled/

# Test nginx configuration
sudo nginx -t
```

### Step 5: Set Up HTTPS with Let's Encrypt

```bash
# First, disable the HTTPS server block in nginx-site.conf temporarily
# Comment out the second server block (listen 443)

sudo systemctl reload nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com

# Certbot will automatically configure nginx
# Or manually uncomment the HTTPS block after certificate generation

sudo systemctl reload nginx
```

### Step 6: Firewall Configuration

```bash
# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## TV Display Setup (Kiosk Mode)

### On Each Display Client (NUC or Raspberry Pi)

#### 1. Install Chromium

```bash
sudo apt update
sudo apt install -y chromium chromium-browser unclutter x11-xserver-utils
```

#### 2. Configure Auto-Login (Optional)

For Debian with LightDM:

```bash
sudo nano /etc/lightdm/lightdm.conf
```

Add:
```ini
[Seat:*]
autologin-user=your-username
autologin-user-timeout=0
```

#### 3. Set Up Kiosk Startup

```bash
# Copy the kiosk startup script
cp kiosk-startup.sh /home/your-username/

# Edit script to set your TV ID and server URL
nano /home/your-username/kiosk-startup.sh
# Change TV_ID and SERVER_URL

# Make executable
chmod +x /home/your-username/kiosk-startup.sh
```

#### 4. Auto-Start on Boot

Create autostart entry:

```bash
mkdir -p ~/.config/autostart
nano ~/.config/autostart/digital-signage.desktop
```

Add:
```ini
[Desktop Entry]
Type=Application
Name=Digital Signage Kiosk
Exec=/home/your-username/kiosk-startup.sh TV_001
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
```

Alternatively, use the startup script directly:

```bash
./kiosk-startup.sh TV_001
```

Replace `TV_001` with the appropriate TV ID for each display.

#### 5. Prevent Screen Blanking

```bash
# Disable screen blanking permanently
sudo nano /etc/X11/xorg.conf.d/10-monitor.conf
```

Add:
```
Section "ServerFlags"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection
```

## Usage Guide

### Dashboard

- Access at `https://your-domain.com/dashboard`
- View all configured TVs
- Create new TV displays (up to 4)
- Quick access to management and display pages

### Managing TV Content

1. Click on a TV card to access its management page
2. Upload PowerPoint presentations (.pptx) - slides are automatically extracted
3. Upload individual images (JPG, PNG, GIF)
4. Drag and drop slides to reorder
5. Adjust slide duration for each slide
6. Delete unwanted slides
7. Preview the display

### Display URL

Each TV has a unique display URL:
```
https://your-domain.com/display/TV_001
https://your-domain.com/display/TV_002
```

These URLs show the fullscreen slideshow without authentication required.

## File Structure

```
digital_signage/
├── main.py                 # Flask application
├── requirements.txt        # Python dependencies
├── creds.txt              # Login credentials (username:password)
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
    │   ├── config.json
    │   ├── 1.jpg
    │   └── 2.jpg
    └── TV_002/
        ├── config.json
        └── ...
```

## Configuration File Format

Each TV has a `config.json` file:

```json
[
  {
    "filename": "1.jpg",
    "duration_seconds": 5
  },
  {
    "filename": "2.jpg",
    "duration_seconds": 10
  }
]
```

## API Endpoints

- `GET /` - Redirect to login or dashboard
- `GET /login` - Login page
- `POST /login` - Authenticate user
- `GET /logout` - Logout
- `GET /dashboard` - Main dashboard
- `GET /tv/<tv_id>` - TV management page
- `GET /display/<tv_id>` - Fullscreen slideshow (no auth)
- `GET /api/check/<tv_id>` - Get current config (for auto-refresh)
- `POST /api/upload_pptx/<tv_id>` - Upload PowerPoint
- `POST /api/upload_image/<tv_id>` - Upload image
- `POST /api/reorder/<tv_id>` - Reorder slides
- `POST /api/update_duration/<tv_id>` - Update slide duration
- `POST /api/delete_slide/<tv_id>` - Delete slide
- `POST /api/create_tv` - Create new TV
- `GET /slides/<tv_id>/<filename>` - Serve slide image

## PowerPoint Conversion Notes

The current implementation extracts images from PowerPoint slides. For best results:

1. Use PowerPoint templates with image backgrounds
2. Export slides as images before uploading (alternative approach)
3. For advanced conversion, consider installing LibreOffice:

```bash
sudo apt install -y libreoffice
```

Then modify `main.py` to use:
```python
import subprocess
subprocess.run(['libreoffice', '--headless', '--convert-to', 'pdf', pptx_file])
# Then convert PDF to images using pdf2image
```

## Troubleshooting

### Service won't start

```bash
# Check logs
sudo journalctl -u digital-signage -f

# Check file permissions
sudo chown -R www-data:www-data /opt/digital_signage
```

### Display not updating

- Check network connectivity on display client
- Verify display URL is correct
- Check browser console for errors (F12)
- Verify slides are uploading correctly in management interface

### Upload fails

- Check nginx client_max_body_size setting
- Verify file permissions on slides directory
- Check available disk space

### Kiosk mode issues

```bash
# Check if Chromium is running
ps aux | grep chromium

# View Chromium output
# Run kiosk-startup.sh manually in terminal to see errors
./kiosk-startup.sh TV_001
```

## Security Considerations

1. **Change default credentials** in `creds.txt`
2. **Use HTTPS** in production (configured via Let's Encrypt)
3. **Firewall rules**: Only expose ports 80 and 443
4. **File permissions**: Ensure slides directory is only writable by www-data
5. **Regular updates**: Keep system packages updated

## Maintenance

### Backup

```bash
# Backup slides and configuration
tar -czf digital-signage-backup-$(date +%Y%m%d).tar.gz \
  /opt/digital_signage/slides \
  /opt/digital_signage/creds.txt
```

### Log Rotation

Logs are managed by systemd. To view:

```bash
sudo journalctl -u digital-signage -n 100
```

### Updating

```bash
# Stop service
sudo systemctl stop digital-signage

# Update code
cd /opt/digital_signage
sudo -u www-data git pull  # if using git

# Update dependencies
sudo -u www-data pyenv/bin/pip install -r requirements.txt --upgrade

# Restart service
sudo systemctl start digital-signage
```

## Performance

- Flask development server is used (suitable for single-user, low traffic)
- Each display checks for updates every 30 seconds
- Images are served directly by Nginx in production
- Target resolution: 1920x1080 (Full HD)
- Supports up to 4 concurrent TV displays

## License

This is a custom implementation for small-scale digital signage deployment.

## Support

For issues or questions, refer to the troubleshooting section or check system logs.
