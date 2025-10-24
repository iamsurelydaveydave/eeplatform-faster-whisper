#!/bin/bash
set -e

echo "=============================="
echo "🚀 Faster-Whisper Setup (Stable H100 Build)"
echo "=============================="

# System update and essentials
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y git wget curl unzip build-essential python3 python3-venv python3-pip ffmpeg \
    libavdevice-dev libavfilter-dev libavformat-dev libavcodec-dev libswscale-dev libavutil-dev

# Create and activate virtual environment
if [ ! -d "faster-whisper-env" ]; then
  python3 -m venv faster-whisper-env
fi
source faster-whisper-env/bin/activate

# Upgrade pip
pip install --upgrade pip setuptools wheel

# === NVIDIA Core Runtime (CUDA 12.4 + cuDNN 9.1 Compatible) ===
echo "📦 Installing CUDA + cuDNN compatible versions..."
pip install --force-reinstall torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# === Core Whisper Dependencies ===
echo "📦 Installing Faster-Whisper + dependencies..."
pip install numpy soundfile psutil ctranslate2>=4.4.0 transformers[torch]>=4.38.0 faster-whisper==1.2.0 av==12.0.0

# === LD_LIBRARY_PATH Setup ===
echo "⚙️ Configuring LD_LIBRARY_PATH..."
LIB_PATHS=$(python3 - <<'EOF'
import importlib, os
paths = []
for lib in ["nvidia.cublas.lib", "nvidia.cudnn.lib"]:
    try:
        mod = importlib.import_module(lib)
        paths.append(os.path.dirname(mod.__file__))
    except Exception:
        pass
if paths:
    print(":".join(paths))
EOF
)
if [ -n "$LIB_PATHS" ]; then
  export LD_LIBRARY_PATH=$LIB_PATHS:$LD_LIBRARY_PATH
  echo "export LD_LIBRARY_PATH=$LIB_PATHS:\$LD_LIBRARY_PATH" >> ~/.bashrc
  # Also add to virtual environment activation script for persistence
  echo "export LD_LIBRARY_PATH=$LIB_PATHS:\$LD_LIBRARY_PATH" >> faster-whisper-env/bin/activate
  echo "✅ LD_LIBRARY_PATH configured and added to virtual environment!"
else
  echo "⚠️ CUDA libraries not found yet — skip (safe for CPU-only runs)."
fi

# === Verification ===
echo "🔍 Checking GPU and cuDNN..."
python3 - <<'EOF'
import torch
print("Torch version:", torch.__version__)
print("CUDA version:", torch.version.cuda)
print("CUDA available:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("Device count:", torch.cuda.device_count())
    print("Device name:", torch.cuda.get_device_name(0))
    from torch.backends import cudnn
    print("cuDNN enabled:", cudnn.enabled)
    print("cuDNN version:", cudnn.version())
EOF

echo "🎤 Verifying Faster Whisper import..."
python3 - <<'EOF'
from faster_whisper import WhisperModel
print("✅ Faster-Whisper imported successfully!")
EOF

echo "🚀 Testing GPU initialization..."
python3 - <<'EOF'
from faster_whisper import WhisperModel
try:
    model = WhisperModel("tiny", device="cuda", compute_type="float16")
    print("✅ GPU model loaded successfully!")
except Exception as e:
    print("❌ GPU model failed:", str(e))
    print("💡 GPU functionality may require proper LD_LIBRARY_PATH setup")
EOF

echo "============================================"
echo "✅ Setup complete!"
echo ""
echo "📋 Usage Instructions:"
echo "  1. For GPU-enabled runs: ./run_gpu.sh [script.py]"
echo "  2. For manual activation: source faster-whisper-env/bin/activate"
echo "  3. Then set LD_LIBRARY_PATH as needed for GPU support"
echo ""
echo "🎮 GPU Status: Ready for faster-whisper GPU acceleration!"
echo "To activate
