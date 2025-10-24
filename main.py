import multiprocessing
import time
from faster_whisper import WhisperModel


def transcribe_audio(device_type, audio_path):
    """Function that runs inside an isolated process for either GPU or CPU."""
    print(f"[{device_type.upper()}] Initializing Faster Whisper model...")
    compute_type = "float16" if device_type == "cuda" else "int8"
    model = WhisperModel("small", device=device_type, compute_type=compute_type)

    print(f"[{device_type.upper()}] Model loaded successfully! Starting transcription...")

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
