import redis
import json
import os
from faster_whisper import WhisperModel
from multiprocessing import Process

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
DEVICE = os.getenv("DEVICE", "cuda")  # "cuda" or "cpu"
MODEL_SIZE = os.getenv("MODEL_SIZE", "small")  # "tiny", "base", "small", "medium", "large"

def worker_main(worker_id):
    # Configure model based on device
    if DEVICE.lower() == "cpu":
        model = WhisperModel(MODEL_SIZE, device="cpu", compute_type="int8")
        device_info = "CPU"
    else:
        model = WhisperModel(MODEL_SIZE, device="cuda", compute_type="float16")
        device_info = "CUDA"
    
    r = redis.Redis(host=REDIS_HOST)
    print(f"[{device_info} Worker {worker_id}] Ready with model: {MODEL_SIZE}")

    while True:
        _, job_json = r.brpop("transcription_queue")
        job = json.loads(job_json)
        job_id = job["jobId"]
        audio_path = job["file_path"]

        print(f"[{device_info} Worker {worker_id}] Processing {audio_path}")
        
        # Set job status to processing
        status_key = f"job:{job_id}:status"
        result_key = f"job:{job_id}:result"
        r.setex(status_key, 3600, json.dumps({
            "status": "processing", 
            "worker_id": worker_id,
            "device": device_info
        }))

        try:
            segments, _ = model.transcribe(audio_path)
            text = " ".join([s.text for s in segments])
            print(f"[{device_info} Worker {worker_id}] Done {job_id}: {text[:50]}")

            # Store result and update status to completed
            result_data = {
                "status": "completed",
                "text": text,
                "worker_id": worker_id,
                "device": device_info,
                "model_size": MODEL_SIZE,
                "file_path": audio_path
            }
            r.setex(result_key, 3600, json.dumps(result_data))  # Expire after 1 hour
            r.setex(status_key, 3600, json.dumps({
                "status": "completed", 
                "worker_id": worker_id,
                "device": device_info
            }))

        except Exception as e:
            print(f"[{device_info} Worker {worker_id}] Error processing {job_id}: {str(e)}")
            
            # Store error result and update status to failed
            error_data = {
                "status": "failed",
                "error": str(e),
                "worker_id": worker_id,
                "device": device_info,
                "file_path": audio_path
            }
            r.setex(result_key, 3600, json.dumps(error_data))
            r.setex(status_key, 3600, json.dumps({
                "status": "failed", 
                "worker_id": worker_id, 
                "device": device_info,
                "error": str(e)
            }))

        finally:
            # Clean up audio file
            try:
                if os.path.exists(audio_path):
                    os.remove(audio_path)
            except Exception as cleanup_error:
                print(f"[{device_info} Worker {worker_id}] Warning: Could not remove {audio_path}: {cleanup_error}")

if __name__ == "__main__":
    # Adjust process count based on device
    if DEVICE.lower() == "cpu":
        N_PROCESSES = int(os.getenv("CPU_WORKERS", "4"))  # CPU workers can be more numerous
    else:
        N_PROCESSES = int(os.getenv("GPU_WORKERS", "2"))  # GPU workers limited by VRAM
    
    print(f"Starting {N_PROCESSES} {DEVICE.upper()} workers with model: {MODEL_SIZE}")
    
    processes = []
    for i in range(N_PROCESSES):
        p = Process(target=worker_main, args=(i,))
        p.start()
        processes.append(p)
    for p in processes:
        p.join()
