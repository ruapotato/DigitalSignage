#!/bin/bash
#
# Digital Signage Setup Script
# Complete installation and system setup
#

set -e  # Exit on error

echo "=========================================="
echo "Digital Signage Management System Setup"
echo "=========================================="
echo ""

# Check if running as root for system package installation
if [ "$EUID" -ne 0 ]; then
    echo "Note: Some operations require root access."
    echo "You may be prompted for your sudo password."
    echo ""
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    echo "Detected OS: $OS"
else
    echo "Warning: Cannot detect OS. Assuming Debian/Ubuntu."
    OS="debian"
fi
echo ""

# Install system dependencies
echo "Installing system dependencies..."
echo "This may take a few minutes..."
echo ""

case $OS in
    debian|ubuntu|raspbian)
        sudo apt-get update
        sudo apt-get install -y \
            python3 \
            python3-pip \
            python3-venv \
            openssl \
            libreoffice \
            libreoffice-writer \
            libreoffice-impress \
            poppler-utils \
            || { echo "Warning: Some packages failed to install"; }
        ;;
    fedora|rhel|centos)
        sudo dnf install -y \
            python3 \
            python3-pip \
            openssl \
            libreoffice \
            poppler-utils \
            || { echo "Warning: Some packages failed to install"; }
        ;;
    arch|manjaro)
        sudo pacman -Sy --noconfirm \
            python \
            python-pip \
            openssl \
            libreoffice-fresh \
            poppler \
            || { echo "Warning: Some packages failed to install"; }
        ;;
    *)
        echo "Warning: Unsupported OS. Please install manually:"
        echo "  - Python 3 and pip"
        echo "  - OpenSSL"
        echo "  - LibreOffice"
        echo "  - poppler-utils (for PDF support)"
        ;;
esac

echo ""
echo "System dependencies installed successfully"
echo ""

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "Found Python $PYTHON_VERSION"

# Create virtual environment if it doesn't exist
if [ ! -d "pyenv" ]; then
    echo ""
    echo "Creating virtual environment..."
    python3 -m venv pyenv
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create virtual environment"
        exit 1
    fi
    echo "Virtual environment created successfully"
else
    echo "Virtual environment already exists"
fi

# Activate virtual environment
echo ""
echo "Activating virtual environment..."
source pyenv/bin/activate

# Install dependencies
echo ""
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

if [ $? -ne 0 ]; then
    echo "Error: Failed to install dependencies"
    exit 1
fi

# Generate SSL certificate if it doesn't exist
echo ""
if [ ! -f "certs/cert.pem" ] || [ ! -f "certs/key.pem" ]; then
    echo "Generating SSL certificate..."
    echo ""
    echo "HTTPS is enabled by default. Generating self-signed certificate..."

    # Check if openssl is available
    if ! command -v openssl &> /dev/null; then
        echo "Warning: openssl not found. Skipping SSL certificate generation."
        echo "You can generate it later by running: ./generate-ssl-cert.sh"
    else
        # Create certs directory
        mkdir -p certs

        # Generate certificate non-interactively with localhost as default
        openssl req -x509 -newkey rsa:4096 -nodes \
            -keyout certs/key.pem \
            -out certs/cert.pem \
            -days 365 \
            -subj "/C=US/ST=State/L=City/O=DigitalSignage/CN=localhost" \
            2>/dev/null

        if [ $? -eq 0 ]; then
            echo "SSL certificate generated successfully!"
            echo "  Certificate: certs/cert.pem"
            echo "  Private Key: certs/key.pem"
            echo "  Valid for: 365 days"
        else
            echo "Warning: Failed to generate SSL certificate"
            echo "You can generate it later by running: ./generate-ssl-cert.sh"
        fi
    fi
else
    echo "SSL certificate already exists"
fi

echo ""
echo "=========================================="
echo "Setup completed successfully!"
echo "=========================================="
echo ""

# Ask about systemd service setup
echo "Would you like to setup systemd service for auto-start? (y/n)"
read -r SETUP_SYSTEMD

if [ "$SETUP_SYSTEMD" = "y" ] || [ "$SETUP_SYSTEMD" = "Y" ]; then
    echo ""
    echo "Setting up systemd service..."

    # Get the current directory (absolute path)
    INSTALL_DIR="$(pwd)"

    # Get current user
    CURRENT_USER="$(whoami)"

    # Create systemd service file
    sudo tee /etc/systemd/system/digital-signage.service > /dev/null <<EOF
[Unit]
Description=Digital Signage Management System
After=network.target

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$INSTALL_DIR
Environment="PATH=$INSTALL_DIR/pyenv/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$INSTALL_DIR/pyenv/bin/python $INSTALL_DIR/main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd daemon
    sudo systemctl daemon-reload

    # Enable the service to start on boot
    sudo systemctl enable digital-signage.service

    echo ""
    echo "Systemd service installed and enabled!"
    echo ""
    echo "Service management commands:"
    echo "  Start:   sudo systemctl start digital-signage"
    echo "  Stop:    sudo systemctl stop digital-signage"
    echo "  Status:  sudo systemctl status digital-signage"
    echo "  Logs:    sudo journalctl -u digital-signage -f"
    echo ""
    echo "Would you like to start the service now? (y/n)"
    read -r START_NOW

    if [ "$START_NOW" = "y" ] || [ "$START_NOW" = "Y" ]; then
        sudo systemctl start digital-signage
        echo ""
        echo "Service started! Checking status..."
        sleep 2
        sudo systemctl status digital-signage --no-pager
    fi
else
    echo ""
    echo "Skipping systemd service setup."
    echo ""
    echo "To start the application manually:"
    echo "  1. Activate virtual environment: source pyenv/bin/activate"
    echo "  2. Run the server: python main.py"
    echo "  3. Open browser: https://localhost:5000"
fi

echo ""
echo "=========================================="
echo "Application Information"
echo "=========================================="
echo ""
echo "Access URL: https://localhost:5000"
echo ""
echo "Default credentials:"
echo "  Username: admin"
echo "  Password: changeme123"
echo ""
echo "IMPORTANT: Change the password in creds.txt before production use!"
echo ""
echo "NOTE: Your browser will show a security warning for the self-signed"
echo "      certificate. Click 'Advanced' and 'Proceed' to continue."
echo ""
echo "To run without HTTPS: python main.py --no-ssl"
echo ""
