#!/bin/bash

# EE Platform Faster Whisper Setup Script
# This script sets up all dependencies and services needed to run the project

set -e  # Exit on any error

echo "🚀 Setting up EE Platform Faster Whisper..."
echo "============================================="

# Check if running as root (recommended for this setup)
if [[ $EUID -eq 0 ]]; then
   echo "✅ Running as root - good for system package installation"
else
   echo "⚠️  Not running as root - some installations may require sudo"
fi

# Update system packages
echo ""
echo "📦 Updating system packages..."
apt update

# Install system dependencies
echo ""
echo "🔧 Installing system dependencies..."
apt install -y redis-server ffmpeg python3-pip nodejs npm

# Start Redis server
echo ""
echo "🗄️  Starting Redis server..."
redis-server --daemonize yes
sleep 2

# Verify Redis is running
if redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis server is running"
else
    echo "❌ Redis server failed to start"
    exit 1
fi

# Install Python dependencies
echo ""
echo "🐍 Installing Python dependencies..."
cd worker
pip install -r requirements.txt
cd ..

# Install Node.js dependencies
echo ""
echo "📦 Installing Node.js dependencies..."
cd api
npm install
cd ..

# Set environment variables (optional)
echo ""
echo "🔧 Setting up environment variables..."
cat > .env << EOF
# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# Worker Configuration
DEVICE=cuda
MODEL_SIZE=small
CPU_WORKERS=10
GPU_WORKERS=10
EOF

# Make scripts executable
chmod +x setup.sh

# Check if sample audio file exists
if [ -f "shared/audio/sample.mp3" ]; then
    echo "✅ Sample audio file found"
else
    echo "⚠️  Sample audio file not found at shared/audio/sample.mp3"
fi

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Start the worker: cd worker && python worker.py"
echo "2. Start the API server: cd api && node index.js"
echo "3. Test the API with: curl -X POST -F 'audio=@shared/audio/sample.mp3' http://localhost:8000/transcribe"
echo ""
echo "🔍 Useful commands:"
echo "- Check Redis status: redis-cli ping"
echo "- Stop Redis: redis-cli shutdown"
echo "- View logs: tail -f /var/log/redis/redis-server.log"
echo ""
echo "✨ Happy transcribing!"