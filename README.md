# EE Platform Faster Whisper

A scalable audio transcription service using OpenAI's Whisper model with Redis queue management.

## Architecture

- **API Server** (Node.js): Handles file uploads and job management
- **Worker** (Python): Processes audio files using faster-whisper
- **Redis**: Job queue and result storage
- **Shared Storage**: Audio file storage

## Quick Start

### 1. Setup Dependencies

Run the setup script to install all required dependencies:

```bash
./setup.sh
```

This will:
- Install system packages (Redis, ffmpeg, etc.)
- Install Python dependencies
- Install Node.js dependencies
- Start Redis server
- Create environment configuration

### 2. Start Services

Use the run script to start all services:

```bash
./run.sh
```

This will start:
- Python worker process
- Node.js API server on port 8000
- Monitor both processes

### 3. Test the System

Run the test script to verify everything works:

```bash
./test.sh
```

This will:
- Upload the sample audio file
- Monitor transcription progress
- Display the results

## Manual Usage

### Start Individual Services

**Start Redis:**
```bash
redis-server --daemonize yes
```

**Start Worker:**
```bash
cd worker
python worker.py
```

**Start API Server:**
```bash
cd api
node index.js
```

### API Endpoints

**Upload Audio File:**
```bash
curl -X POST -F 'audio=@path/to/audio.mp3' http://localhost:8000/transcribe
```

**Check Job Status:**
```bash
curl http://localhost:8000/status/{jobId}
```

## Configuration

Create a `.env` file in the project root to customize settings:

```bash
# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# Worker Configuration
DEVICE=cuda         # or 'cpu' (this setting is overridden by mixed mode)
MODEL_SIZE=small    # tiny, base, small, medium, large
CPU_WORKERS=10      # Number of CPU workers (runs in parallel with GPU workers)
GPU_WORKERS=10      # Number of GPU workers (runs in parallel with CPU workers)
```

**Mixed Worker Mode**: The system now runs both CPU and GPU workers simultaneously for maximum throughput. CPU workers use `int8` compute type for efficiency, while GPU workers use `float16` for speed. This allows optimal resource utilization across your hardware.

## Supported Audio Formats

- MP3 (.mp3)
- WAV (.wav)
- OGG (.ogg)
- WebM (.webm)
- FLAC (.flac)
- AAC (.aac)
- M4A (.m4a)
- MP4 (.mp4)

## Response Format

**Upload Response:**
```json
{
  "jobId": "uuid-string",
  "status": "queued",
  "filename": "audio.mp3",
  "size": 1234567
}
```

**Status Response:**
```json
{
  "status": "completed",
  "text": "Transcribed text here...",
  "worker_id": 0,
  "device": "CPU",
  "model_size": "small",
  "file_path": "/path/to/audio"
}
```

## Troubleshooting

**Redis Connection Issues:**
```bash
# Check if Redis is running
redis-cli ping

# Start Redis manually
redis-server --daemonize yes
```

**Worker Issues:**
```bash
# Check Python dependencies
pip list | grep -E "(faster-whisper|torch|redis)"

# Run worker with debug output
cd worker && python worker.py
```

**API Server Issues:**
```bash
# Check Node.js dependencies
cd api && npm list

# Check if port 8000 is available
netstat -tlnp | grep :8000
```

**File Upload Issues:**
- Check file size (max 100MB)
- Verify file format is supported
- Ensure proper file permissions

## Development

### Project Structure
```
├── api/              # Node.js API server
│   ├── index.js      # Main server file
│   └── package.json  # Dependencies
├── worker/           # Python worker
│   ├── worker.py     # Main worker file
│   └── requirements.txt
├── shared/           # Shared storage
│   └── audio/        # Audio files
├── setup.sh          # Setup script
├── run.sh            # Run script
└── test.sh           # Test script
```

### Environment Variables

**API Server:**
- `REDIS_HOST`: Redis server host (default: localhost)
- `REDIS_PORT`: Redis server port (default: 6379)

**Worker:**
- `REDIS_HOST`: Redis server host (default: redis)
- `DEVICE`: Processing device (cpu/cuda, default: cuda)
- `MODEL_SIZE`: Whisper model size (default: small)
- `CPU_WORKERS`: Number of CPU workers (default: 4)
- `GPU_WORKERS`: Number of GPU workers (default: 2)

## License

MIT License