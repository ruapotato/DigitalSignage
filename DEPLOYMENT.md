# Production Deployment Guide

This guide provides step-by-step instructions for deploying the Digital Signage Management System in a production environment.

## Pre-Deployment Checklist

- [ ] Debian 11+ server with root access
- [ ] Domain name pointing to your server
- [ ] Firewall configured (ports 80, 443)
- [ ] At least 10GB free disk space
- [ ] Updated system packages

## Server Setup

### 1. Update System

```bash
sudo apt update
sudo apt upgrade -y
```

### 2. Install Required Packages

```bash
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

### 3. Create Application User

```bash
# The application will run as www-data, ensure it exists
id www-data || sudo useradd -r -s /bin/false www-data
```

## Application Deployment

### 1. Deploy Application Files

```bash
# Create application directory
sudo mkdir -p /opt/digital_signage
sudo chown $USER:$USER /opt/digital_signage

# Copy application files
cd /path/to/source
sudo cp -r * /opt/digital_signage/

# Set ownership
sudo chown -R www-data:www-data /opt/digital_signage

# Set permissions
sudo chmod 755 /opt/digital_signage
sudo chmod 750 /opt/digital_signage/slides
sudo chmod 640 /opt/digital_signage/creds.txt
```

### 2. Configure Credentials

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

### 3. Set Up Python Environment

```bash
cd /opt/digital_signage

# Create virtual environment as www-data
sudo -u www-data python3 -m venv pyenv

# Install dependencies
sudo -u www-data pyenv/bin/pip install --upgrade pip
sudo -u www-data pyenv/bin/pip install -r requirements.txt
```

## Systemd Service Configuration

### 1. Install Service File

```bash
# Copy service file
sudo cp /opt/digital_signage/digital-signage.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable service
sudo systemctl enable digital-signage

# Start service
sudo systemctl start digital-signage

# Check status
sudo systemctl status digital-signage
```

### 2. Verify Service

```bash
# Check if application is running
curl http://localhost:5000

# View logs
sudo journalctl -u digital-signage -f
```

## Nginx Configuration

### 1. Configure Nginx (Before SSL)

```bash
# Edit nginx configuration
sudo cp /opt/digital_signage/nginx-site.conf /tmp/nginx-site.conf

# Replace your-domain.com with actual domain
sudo sed -i 's/your-domain.com/youractual.domain.com/g' /tmp/nginx-site.conf

# Temporarily remove SSL configuration for initial setup
sudo nano /tmp/nginx-site.conf
# Comment out the entire second server block (listen 443)
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

### 2. Obtain SSL Certificate

```bash
# Run certbot
sudo certbot --nginx -d youractual.domain.com

# Follow the prompts
# Certbot will automatically configure nginx for HTTPS

# Test auto-renewal
sudo certbot renew --dry-run
```

### 3. Final Nginx Configuration

After certbot succeeds, restore the full nginx configuration:

```bash
# Use the original configuration with SSL paths
sudo cp /opt/digital_signage/nginx-site.conf /tmp/nginx-final.conf

# Update domain
sudo sed -i 's/your-domain.com/youractual.domain.com/g' /tmp/nginx-final.conf

# Install
sudo cp /tmp/nginx-final.conf /etc/nginx/sites-available/digital-signage

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

## Firewall Configuration

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

## Monitoring and Logs

### Service Logs

```bash
# View real-time logs
sudo journalctl -u digital-signage -f

# View last 100 lines
sudo journalctl -u digital-signage -n 100

# View logs since last boot
sudo journalctl -u digital-signage -b
```

### Nginx Logs

```bash
# Access logs
sudo tail -f /var/log/nginx/access.log

# Error logs
sudo tail -f /var/log/nginx/error.log
```

## Display Client Setup (TV/Kiosk)

### For Each TV Display Device

#### 1. Install Required Packages

```bash
sudo apt update
sudo apt install -y \
    chromium \
    chromium-browser \
    unclutter \
    x11-xserver-utils \
    xserver-xorg \
    xinit
```

#### 2. Configure Kiosk Script

```bash
# Copy kiosk script to user home
cp /opt/digital_signage/kiosk-startup.sh ~/kiosk-startup.sh

# Edit configuration
nano ~/kiosk-startup.sh

# Update these variables:
# TV_ID="TV_001"  # Change to TV_001, TV_002, etc.
# SERVER_URL="https://youractual.domain.com"

# Make executable
chmod +x ~/kiosk-startup.sh
```

#### 3. Test Kiosk Mode

```bash
# Test manually first
./kiosk-startup.sh
```

#### 4. Auto-Start Configuration

##### Method 1: Desktop Autostart (for GUI environments)

```bash
mkdir -p ~/.config/autostart

cat > ~/.config/autostart/digital-signage.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Digital Signage Kiosk
Exec=/home/USERNAME/kiosk-startup.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Replace USERNAME with actual username
sed -i "s/USERNAME/$USER/g" ~/.config/autostart/digital-signage.desktop
```

##### Method 2: Systemd User Service

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/digital-signage-kiosk.service << 'EOF'
[Unit]
Description=Digital Signage Kiosk Display
After=graphical.target

[Service]
Type=simple
Environment=DISPLAY=:0
ExecStart=/home/USERNAME/kiosk-startup.sh
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

# Replace USERNAME
sed -i "s/USERNAME/$USER/g" ~/.config/systemd/user/digital-signage-kiosk.service

# Enable service
systemctl --user enable digital-signage-kiosk
systemctl --user start digital-signage-kiosk
```

#### 5. Disable Screen Blanking

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

#### 6. Auto-Login (Optional)

For automatic login with LightDM:

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

## Backup Strategy

### 1. Create Backup Script

```bash
sudo tee /opt/digital_signage/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/digital-signage"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

tar -czf $BACKUP_DIR/slides-$DATE.tar.gz \
    -C /opt/digital_signage slides

cp /opt/digital_signage/creds.txt $BACKUP_DIR/creds-$DATE.txt

# Keep only last 7 backups
cd $BACKUP_DIR
ls -t slides-*.tar.gz | tail -n +8 | xargs -r rm
ls -t creds-*.txt | tail -n +8 | xargs -r rm

echo "Backup completed: $DATE"
EOF

sudo chmod +x /opt/digital_signage/backup.sh
```

### 2. Schedule Backups with Cron

```bash
# Add daily backup at 2 AM
(sudo crontab -l 2>/dev/null; echo "0 2 * * * /opt/digital_signage/backup.sh") | sudo crontab -
```

## Maintenance Tasks

### Update Application

```bash
# Stop service
sudo systemctl stop digital-signage

# Pull updates (if using git)
cd /opt/digital_signage
sudo -u www-data git pull

# Update dependencies
sudo -u www-data pyenv/bin/pip install -r requirements.txt --upgrade

# Restart service
sudo systemctl start digital-signage
```

### Restart Service

```bash
sudo systemctl restart digital-signage
```

### View Service Status

```bash
sudo systemctl status digital-signage
```

### Clear Slides for a TV

```bash
# Backup first
sudo cp /opt/digital_signage/slides/TV_001/config.json /tmp/

# Clear slides
sudo rm -f /opt/digital_signage/slides/TV_001/*.jpg

# Reset config
echo "[]" | sudo tee /opt/digital_signage/slides/TV_001/config.json
```

## Troubleshooting

### Service Won't Start

```bash
# Check logs
sudo journalctl -u digital-signage -n 50

# Check if port 5000 is in use
sudo netstat -tlnp | grep 5000

# Check permissions
sudo ls -la /opt/digital_signage
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

### SSL Certificate Issues

```bash
# Check certificate status
sudo certbot certificates

# Renew manually
sudo certbot renew

# Test renewal
sudo certbot renew --dry-run
```

### Display Not Updating

1. Check network connectivity from display client
2. Verify URL is accessible from display: `curl https://yourdomain.com/display/TV_001`
3. Check browser console (F12) for JavaScript errors
4. Verify slides exist in management interface
5. Check that config.json is properly formatted

### High Memory Usage

```bash
# Check memory usage
free -h

# Restart service to clear memory
sudo systemctl restart digital-signage
```

## Performance Tuning

### Nginx Caching

Add to nginx configuration inside server block:

```nginx
location ~* \.(jpg|jpeg|png|gif)$ {
    expires 1h;
    add_header Cache-Control "public, immutable";
}
```

### System Resources

For better performance on resource-constrained devices:

```bash
# Reduce Chromium memory usage in kiosk-startup.sh
# Add these flags to chromium command:
--disk-cache-size=52428800
--media-cache-size=52428800
```

## Security Hardening

### 1. Limit Nginx Access (Optional)

If only internal network access is needed:

```nginx
# In nginx config, add to location /:
allow 192.168.1.0/24;  # Your internal network
deny all;

# Keep /display/ public for TV access
location /display/ {
    # No restrictions
    proxy_pass http://127.0.0.1:5000;
}
```

### 2. Enable Fail2Ban (Optional)

```bash
sudo apt install -y fail2ban

# Configure for nginx
sudo nano /etc/fail2ban/jail.local
```

### 3. Regular Updates

```bash
# Create update script
sudo tee /opt/update-system.sh << 'EOF'
#!/bin/bash
apt update
apt upgrade -y
apt autoremove -y
systemctl restart digital-signage
EOF

sudo chmod +x /opt/update-system.sh

# Schedule monthly updates
(sudo crontab -l 2>/dev/null; echo "0 3 1 * * /opt/update-system.sh") | sudo crontab -
```

## Support Checklist

Before reporting issues:

- [ ] Check service status: `sudo systemctl status digital-signage`
- [ ] Review logs: `sudo journalctl -u digital-signage -n 100`
- [ ] Verify nginx configuration: `sudo nginx -t`
- [ ] Test backend directly: `curl http://localhost:5000`
- [ ] Check disk space: `df -h`
- [ ] Verify file permissions
- [ ] Test from display client
- [ ] Review nginx logs

## Post-Deployment Verification

1. Access `https://yourdomain.com` - should redirect to login
2. Login with credentials from `/root/digital-signage-password.txt`
3. Create a test TV
4. Upload a test image
5. Access display URL from another device
6. Verify slideshow plays correctly
7. Test updating slide duration
8. Test reordering slides
9. Test deleting slides

Deployment complete!
