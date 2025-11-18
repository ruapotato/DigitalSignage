#!/bin/bash
#
# Digital Signage Setup Script
# Quick setup for development/testing
#

echo "=========================================="
echo "Digital Signage Management System Setup"
echo "=========================================="
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

echo ""
echo "=========================================="
echo "Setup completed successfully!"
echo "=========================================="
echo ""
echo "To start the application:"
echo "  1. Activate virtual environment: source pyenv/bin/activate"
echo "  2. Run the server: python main.py"
echo "  3. Open browser: http://localhost:5000"
echo ""
echo "Default credentials:"
echo "  Username: admin"
echo "  Password: changeme123"
echo ""
echo "IMPORTANT: Change the password in creds.txt before production use!"
echo ""
