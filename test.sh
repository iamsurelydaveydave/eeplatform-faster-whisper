#!/bin/bash

# EE Platform Faster Whisper Test Script
# This script tests the transcription API with the sample audio file

set -e

API_URL="http://localhost:3000"
SAMPLE_FILE="shared/audio/sample.mp3"

echo "🧪 Testing EE Platform Faster Whisper API..."
echo "============================================"

# Check if API server is running
echo "🔍 Checking if API server is running..."
if curl -s -f "$API_URL" > /dev/null 2>&1; then
    echo "✅ API server is accessible"
else
    echo "❌ API server is not running at $API_URL"
    echo "💡 Please run: ./run.sh"
    exit 1
fi

# Check if sample file exists
if [ ! -f "$SAMPLE_FILE" ]; then
    echo "❌ Sample audio file not found at $SAMPLE_FILE"
    exit 1
fi

echo "✅ Sample audio file found"

# Upload audio file for transcription
echo ""
echo "📤 Uploading audio file for transcription..."
RESPONSE=$(curl -s -X POST -F "audio=@$SAMPLE_FILE" "$API_URL/transcribe")

if [ $? -ne 0 ]; then
    echo "❌ Failed to upload audio file"
    exit 1
fi

echo "📄 Upload response:"
echo "$RESPONSE" | python3 -m json.tool

# Extract job ID
JOB_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['jobId'])" 2>/dev/null)

if [ -z "$JOB_ID" ]; then
    echo "❌ Failed to extract job ID from response"
    exit 1
fi

echo ""
echo "🔄 Job ID: $JOB_ID"
echo "⏳ Waiting for transcription to complete..."

# Poll for results
MAX_ATTEMPTS=30
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo "🔍 Checking status (attempt $ATTEMPT/$MAX_ATTEMPTS)..."
    
    STATUS_RESPONSE=$(curl -s "$API_URL/status/$JOB_ID")
    STATUS=$(echo "$STATUS_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', 'unknown'))" 2>/dev/null)
    
    echo "📊 Status: $STATUS"
    
    if [ "$STATUS" = "completed" ]; then
        echo ""
        echo "🎉 Transcription completed!"
        echo "📄 Full response:"
        echo "$STATUS_RESPONSE" | python3 -m json.tool
        
        # Extract and display just the transcribed text
        TEXT=$(echo "$STATUS_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('text', 'No text found'))" 2>/dev/null)
        echo ""
        echo "📝 Transcribed text:"
        echo "\"$TEXT\""
        break
    elif [ "$STATUS" = "failed" ]; then
        echo ""
        echo "❌ Transcription failed!"
        echo "📄 Error response:"
        echo "$STATUS_RESPONSE" | python3 -m json.tool
        exit 1
    elif [ "$STATUS" = "processing" ]; then
        echo "⏳ Still processing..."
    elif [ "$STATUS" = "queued" ]; then
        echo "📋 Still queued..."
    else
        echo "❓ Unknown status: $STATUS"
    fi
    
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo "⏰ Timeout waiting for transcription to complete"
        echo "📄 Last response:"
        echo "$STATUS_RESPONSE" | python3 -m json.tool
        exit 1
    fi
    
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

echo ""
echo "✅ Test completed successfully!"