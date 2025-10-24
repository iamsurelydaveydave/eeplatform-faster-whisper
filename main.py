import multiprocessing
import time
import torch
from faster_whisper import WhisperModel


def transcribe_audio(device_type, audio_path):
    """Function that runs inside an isolated process for either GPU or CPU."""
    print(f"[{device_type.upper()}] Initializing Faster Whisper model...")
    
    # Verify CUDA availability for GPU processes
    if device_type == "cuda":
        if not torch.cuda.is_available():
            print(f"[{device_type.upper()}] ❌ CUDA not available, falling back to CPU")
            device_type = "cpu"
        else:
            print(f"[{device_type.upper()}] ✅ CUDA available - GPU: {torch.cuda.get_device_name(0)}")
    
    compute_type = "float16" if device_type == "cuda" else "int8"
    
    try:
        model = WhisperModel("small", device=device_type, compute_type=compute_type)
        print(f"[{device_type.upper()}] ✅ Model loaded successfully on {device_type.upper()}!")
    except Exception as e:
        print(f"[{device_type.upper()}] ❌ Model loading failed: {str(e)}")
        if device_type == "cuda":
            print(f"[{device_type.upper()}] Falling back to CPU...")
            device_type = "cpu"
            compute_type = "int8"
            model = WhisperModel("small", device=device_type, compute_type=compute_type)
            print(f"[{device_type.upper()}] ✅ Model loaded successfully on CPU fallback!")
        else:
            raise

    print(f"[{device_type.upper()}] Starting transcription...")

    segments, info = model.transcribe(audio_path, beam_size=5)
    print(f"[{device_type.upper()}] Detected language: {info.language} (prob: {info.language_probability:.2f})")

    for segment in segments:
        print(f"[{device_type.upper()}] [{segment.start:.2f}s -> {segment.end:.2f}s] {segment.text}")

    print(f"[{device_type.upper()}] Transcription complete!")


def run_gpu_process(audio_path):
    process = multiprocessing.Process(target=transcribe_audio, args=("cuda", audio_path))
    process.start()
    return process


def run_cpu_process(audio_path):
    process = multiprocessing.Process(target=transcribe_audio, args=("cpu", audio_path))
    process.start()
    return process


if __name__ == "__main__":
    AUDIO_FILE = "sample.mp3"  # Change this to your test audio file

    print("🚀 Starting transcription processes...")
    gpu_proc = run_gpu_process(AUDIO_FILE)
    cpu_proc = run_cpu_process(AUDIO_FILE)

    # Optional: wait for both to finish
    gpu_proc.join()
    cpu_proc.join()

    print("✅ All transcriptions completed!")
