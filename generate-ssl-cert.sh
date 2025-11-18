#!/bin/bash
#
# Generate Self-Signed SSL Certificate for Digital Signage
# This creates a self-signed certificate for development/testing
#

echo "=========================================="
echo "SSL Certificate Generator"
echo "=========================================="
echo ""

# Create certs directory if it doesn't exist
mkdir -p certs

# Check if certificate already exists
if [ -f "certs/cert.pem" ] && [ -f "certs/key.pem" ]; then
    echo "SSL certificates already exist in certs/ directory."
    read -p "Overwrite existing certificates? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing certificates."
        exit 0
    fi
fi

# Get hostname/IP
echo "Enter the hostname or IP address for the certificate"
echo "(e.g., localhost, 192.168.1.100, signage.local)"
read -p "Hostname/IP [localhost]: " HOSTNAME
HOSTNAME=${HOSTNAME:-localhost}

# Generate self-signed certificate
echo ""
echo "Generating self-signed SSL certificate..."
echo "Country: US"
echo "State: State"
echo "City: City"
echo "Organization: Digital Signage"
echo "Common Name: $HOSTNAME"

openssl req -x509 -newkey rsa:4096 -nodes \
    -keyout certs/key.pem \
    -out certs/cert.pem \
    -days 365 \
    -subj "/C=US/ST=State/L=City/O=DigitalSignage/CN=$HOSTNAME" \
    2>/dev/null

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "SSL Certificate Generated Successfully!"
    echo "=========================================="
    echo ""
    echo "Certificate: certs/cert.pem"
    echo "Private Key: certs/key.pem"
    echo "Valid for: 365 days"
    echo "Common Name: $HOSTNAME"
    echo ""
    echo "To start Flask with HTTPS:"
    echo "  python main.py --ssl"
    echo ""
    echo "Access at: https://$HOSTNAME:5000"
    echo ""
    echo "NOTE: Browsers will show a security warning for self-signed certificates."
    echo "This is expected. Click 'Advanced' and 'Proceed' to access the site."
    echo ""
else
    echo "Error: Failed to generate certificate"
    exit 1
fi
