#!/bin/bash

# Script to set up HTTPS for VibeTunnel development
# This creates a self-signed certificate for testing push notifications

echo "🔐 Setting up HTTPS for VibeTunnel development..."

# Create certificates directory
mkdir -p certificates

# Generate a self-signed certificate
openssl req -x509 -newkey rsa:4096 -nodes -out certificates/cert.pem -keyout certificates/key.pem -days 365 \
  -subj "/C=US/ST=State/L=City/O=VibeTunnel Dev/CN=localhost" \
  -addext "subjectAltName = DNS:localhost, IP:127.0.0.1, IP:192.168.158.199"

echo "✅ Certificate created!"
echo ""
echo "To use HTTPS, update your VibeTunnel server configuration to use these certificates:"
echo "  - Certificate: $(pwd)/certificates/cert.pem"
echo "  - Private Key: $(pwd)/certificates/key.pem"
echo ""
echo "You'll need to accept the self-signed certificate warning in your browser."