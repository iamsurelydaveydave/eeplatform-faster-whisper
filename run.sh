#!/bin/bash

# EE Platform Faster Whisper Run Script
# This script starts all services needed to run the project

set -e

echo "🚀 Starting EE Platform Faster Whisper..."
echo "========================================="

# Check if Redis is running
echo "🔍 Checking Redis server..."
if redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis server is running"
else
    echo "🔄 Starting Redis server..."
    redis-server --daemonize yes
    sleep 2
    if redis-cli ping > /dev/null 2>&1; then
        echo "✅ Redis server started successfully"
    else
        echo "❌ Failed to start Redis server"
        exit 1
    fi
fi

# Function to handle cleanup
cleanup() {
    echo ""
    echo "🛑 Shutting down services..."
    if [ ! -z "$WORKER_PID" ]; then
        kill $WORKER_PID 2>/dev/null || true
        echo "✅ Worker stopped"
    fi
    if [ ! -z "$API_PID" ]; then
        kill $API_PID 2>/dev/null || true
        echo "✅ API server stopped"
    fi
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Start the worker in background
echo ""
echo "🔧 Starting Python worker..."
cd worker
export REDIS_HOST=${REDIS_HOST:-localhost}
export DEVICE=${DEVICE:-cuda}
export CPU_WORKERS=${CPU_WORKERS:-10}
export GPU_WORKERS=${GPU_WORKERS:-10}
export MODEL_SIZE=${MODEL_SIZE:-small}
python worker.py &
WORKER_PID=$!
echo "✅ Worker started (PID: $WORKER_PID)"
cd ..

# Wait a bit for worker to initialize
sleep 3

# Start the API server in background
echo ""
echo "🌐 Starting API server..."
cd api
export REDIS_HOST=${REDIS_HOST:-localhost}
export REDIS_PORT=${REDIS_PORT:-6379}
node index.js &
API_PID=$!
echo "✅ API server started (PID: $API_PID)"
cd ..

echo ""
echo "🎉 All services are running!"
echo ""
echo "📡 API Server: http://localhost:8000"
echo "🔍 Test endpoint: POST /transcribe"
echo "📊 Status endpoint: GET /status/:jobId"
echo ""
echo "🧪 Test with sample file:"
echo "curl -X POST -F 'audio=@shared/audio/sample.mp3' http://localhost:8000/transcribe"
echo ""
echo "📝 Press Ctrl+C to stop all services"
echo ""

# Wait for user to stop the services
wait