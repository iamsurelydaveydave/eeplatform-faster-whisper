# 🎤 Faster-Whisper GPU Platform

A high-performance speech-to-text transcription platform using OpenAI's Whisper model with GPU acceleration via faster-whisper and ctranslate2.

## 🚀 Features

- **GPU Acceleration**: Optimized for NVIDIA GPUs with CUDA support
- **Parallel Processing**: Simultaneous CPU and GPU transcription
- **Automatic Fallback**: Falls back to CPU if GPU initialization fails
- **Easy Setup**: One-command installation and configuration
- **Production Ready**: Robust error handling and environment management

## 📋 Prerequisites

- **OS**: Linux (tested on Ubuntu)
- **GPU**: NVIDIA GPU with CUDA support (tested on H100)
- **Python**: 3.8+ (Python 3.12 recommended)
- **CUDA**: Compatible NVIDIA drivers

## 🛠️ Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/iamsurelydaveydave/eeplatform-faster-whisper.git
cd eeplatform-faster-whisper
```

### 2. Run Setup (One-Time Installation)
```bash
./setup.sh
```

This will:
- Install system dependencies (ffmpeg, build tools)
- Create and configure Python virtual environment
- Install PyTorch 2.6.0 with CUDA 12.4 support
- Install faster-whisper and dependencies
- Configure GPU library paths
- Verify GPU functionality

### 3. Run GPU-Accelerated Transcription
```bash
./run_gpu.sh
```

That's it! The script will transcribe the included `sample.mp3` file using both GPU and CPU in parallel.

## 📁 Project Structure

```
eeplatform-faster-whisper/
├── main.py              # Main transcription script
├── setup.sh             # One-time setup script
├── run_gpu.sh           # GPU-enabled execution wrapper
├── requirements.txt     # Python dependencies
├── sample.mp3           # Test audio file
├── faster-whisper-env/  # Python virtual environment
└── README.md            # This file
```

## 🎮 Usage Examples

### Basic GPU Transcription
```bash
# Use the wrapper script (recommended)
./run_gpu.sh

# Or activate environment manually
source faster-whisper-env/bin/activate
export LD_LIBRARY_PATH="$(python -c 'import nvidia.cudnn.lib, nvidia.cublas.lib, os; print(":".join([os.path.dirname(nvidia.cudnn.lib.__file__), os.path.dirname(nvidia.cublas.lib.__file__)]))')":$LD_LIBRARY_PATH
python main.py
```

### Custom Audio File
```bash
# Edit main.py to change the AUDIO_FILE variable
# Then run:
./run_gpu.sh
```

### Run Custom Script with GPU Support
```bash
./run_gpu.sh your_script.py
```

## 🔧 Configuration

### Audio File Configuration
Edit `main.py` and change the `AUDIO_FILE` variable:
```python
AUDIO_FILE = "your_audio_file.mp3"  # Change this to your audio file
```

### Model Configuration
Modify the model size in `main.py`:
```python
# Available models: tiny, base, small, medium, large, large-v2, large-v3
model = WhisperModel("small", device=device_type, compute_type=compute_type)
```

### GPU Settings
Adjust GPU compute type in `main.py`:
```python
compute_type = "float16"  # Options: float16, int8_float16, int8
```

## 🐛 Troubleshooting

### GPU Not Working
1. **Check NVIDIA drivers**: `nvidia-smi`
2. **Verify CUDA**: `python -c "import torch; print(torch.cuda.is_available())"`
3. **Run setup again**: `./setup.sh`
4. **Check GPU memory**: Ensure sufficient VRAM available

### Library Path Issues
```bash
# If you get cuDNN loading errors, manually set library path:
export LD_LIBRARY_PATH="$(python -c 'import nvidia.cudnn.lib, nvidia.cublas.lib, os; print(":".join([os.path.dirname(nvidia.cudnn.lib.__file__), os.path.dirname(nvidia.cublas.lib.__file__)]))')":$LD_LIBRARY_PATH
```

### Permission Issues
```bash
# Make scripts executable
chmod +x setup.sh run_gpu.sh
```

## 📊 Performance

- **GPU**: ~10-30x faster than CPU (depending on hardware)
- **Memory**: ~2-4GB VRAM for small model
- **Accuracy**: Same as OpenAI Whisper (bit-exact)

## 🔄 Dependencies

### Core Dependencies
- `faster-whisper==1.2.0` - Optimized Whisper implementation
- `torch==2.6.0+cu124` - PyTorch with CUDA 12.4
- `ctranslate2>=4.4.0` - Optimized inference engine
- `nvidia-cudnn-cu12==9.1.0.70` - NVIDIA cuDNN

### System Dependencies
- `ffmpeg` - Audio processing
- `python3-dev` - Python development headers
- `build-essential` - Compilation tools

## 🚀 Deployment

### Fresh Installation on New System
```bash
git clone https://github.com/iamsurelydaveydave/eeplatform-faster-whisper.git
cd eeplatform-faster-whisper
./setup.sh
./run_gpu.sh
```

### Docker (Future Enhancement)
```dockerfile
# Dockerfile coming soon for containerized deployment
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [OpenAI Whisper](https://github.com/openai/whisper) - Original model
- [faster-whisper](https://github.com/guillaumekln/faster-whisper) - Optimized implementation
- [CTranslate2](https://github.com/OpenNMT/CTranslate2) - Inference engine
- [PyTorch](https://pytorch.org/) - ML framework

## 📞 Support

For issues and questions:
- Open an [issue](https://github.com/iamsurelydaveydave/eeplatform-faster-whisper/issues)
- Check existing issues for solutions
- Ensure you've run `./setup.sh` successfully

---

**🎉 Happy Transcribing!** 🎤➡️📝