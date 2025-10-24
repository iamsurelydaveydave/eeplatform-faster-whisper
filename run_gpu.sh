#!/bin/bash
# Faster-Whisper GPU Runtime Script
# This script properly sets up the environment and runs your Python script with GPU support

set -e

echo "🚀 Starting Faster-Whisper with GPU support..."

# Activate virtual environment
source faster-whisper-env/bin/activate

# Set up LD_LIBRARY_PATH for cuDNN
echo "⚙️ Setting up CUDA library paths..."
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
    echo "✅ LD_LIBRARY_PATH configured!"
else
    echo "⚠️ Warning: CUDA libraries not found in expected location"
fi

# Run the provided script or main.py by default
SCRIPT=${1:-"main.py"}
echo "🎤 Running $SCRIPT..."
python3 "$SCRIPT"