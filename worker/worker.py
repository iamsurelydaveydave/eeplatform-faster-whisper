import redis
import json
import os
from faster_whisper import WhisperModel
from multiprocessing import Process

REDIS_HOST = os.getenv("REDIS_HOST", "redis")

def worker_main(worker_id):
    model = WhisperModel("small", device="cuda", compute_type="float16")
    r = redis.Redis(host=REDIS_HOST)
    print(f"[Worker {worker_id}] Ready")

    while True:
        _, job_json = r.brpop("transcription_queue")
        job = json.loads(job_json)
        audio_path = job["file_path"]

        print(f"[Worker {worker_id}] Processing {audio_path}")

        segments, _ = model.transcribe(audio_path)
        text = " ".join([s.text for s in segments])
        print(f"[Worker {worker_id}] Done {job['job_id']}: {text[:50]}")

        os.remove(audio_path)

if __name__ == "__main__":
    N_PROCESSES = 5  # Adjust based on GPU/VRAM
    processes = []
    for i in range(N_PROCESSES):
        p = Process(target=worker_main, args=(i,))
        p.start()
        processes.append(p)
    for p in processes:
        p.join()
