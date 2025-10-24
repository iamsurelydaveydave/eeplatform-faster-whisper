#!/bin/bash
set -e

echo "=============================="
echo "🚀 Faster Whisper Setup Script"
echo "=============================="

# Update system
sudo apt update -y && sudo apt upgrade -y

# Basic tools
sudo apt install -y git wget curl unzip ffmpeg build-essential python3 python3-venv python3-pip

# Create Python venv
if [ ! -d "faster-whisper-env" ]; then
  python3 -m venv faster-whisper-env
fi
source faster-whisper-env/bin/activate

# Upgrade pip
pip install --upgrade pip setuptools wheel

# Install NVIDIA CUDA runtime libraries (for GPU users)
# This includes cuBLAS and cuDNN 9 (CUDA 12)
echo "📦 Installing NVIDIA CUDA 12 libraries..."
pip install nvidia-cublas-cu12 nvidia-cudnn-cu12==9.*

# Configure LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$(python3 -c 'import os; import nvidia.cublas.lib; import nvidia.cudnn.lib; print(os.path.dirname(nvidia.cublas.lib.__file__) + ":" + os.path.dirname(nvidia.cudnn.lib.__file__))')
echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> ~/.bashrc

# Install Faster Whisper and dependencies
echo "📦 Installing Faster Whisper..."
pip install faster-whisper pyav numpy torch soundfile

# Optional: Install dependencies for model conversion
pip install transformers[torch] ctranslate2

# Verify GPU availability
echo "🔍 Checking GPU availability..."
python3 - <<'EOF'
import torch
print("CUDA available:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("CUDA device:", torch.cuda.get_device_name(0))
EOF

# Test faster-whisper installation
echo "🎤 Verifying Faster Whisper setup..."
python3 - <<'EOF'
from faster_whisper import WhisperModel
print("✅ Faster Whisper imported successfully!")
EOF

echo "============================================"
echo "✅ Setup complete!"
echo "To activate environment next time, run:"
echo "source faster-whisper-env/bin/activate"
echo "============================================"
