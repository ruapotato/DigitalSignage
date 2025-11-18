#!/bin/bash
#
# Chromium Kiosk Mode Startup Script for Digital Signage
# This script starts Chromium in kiosk mode for displaying digital signage
#
# Usage: ./kiosk-startup.sh [TV_ID]
# Example: ./kiosk-startup.sh TV_001
#
# To auto-start on boot, add to ~/.config/autostart/ or use systemd
#

# Configuration
TV_ID="${1:-TV_001}"  # Default to TV_001 if not specified
SERVER_URL="https://your-domain.com"  # Change to your server URL
DISPLAY_URL="${SERVER_URL}/display/${TV_ID}"

# Wait for network to be ready
echo "Waiting for network connection..."
while ! ping -c 1 -W 1 google.com > /dev/null 2>&1; do
    sleep 1
done
echo "Network is ready"

# Disable screen blanking and power management
xset s off
xset s noblank
xset -dpms

# Hide mouse cursor after inactivity (requires unclutter)
if command -v unclutter &> /dev/null; then
    unclutter -idle 3 &
fi

# Kill any existing Chromium instances
pkill chromium

# Wait a moment
sleep 2

# Start Chromium in kiosk mode
chromium \
    --kiosk \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-suggestions-service \
    --disable-translate \
    --disable-save-password-bubble \
    --disable-features=TranslateUI \
    --no-first-run \
    --fast \
    --fast-start \
    --disable-restore-session-state \
    --disable-popup-blocking \
    --start-fullscreen \
    --check-for-update-interval=31536000 \
    "${DISPLAY_URL}" &

# Keep script running
wait
