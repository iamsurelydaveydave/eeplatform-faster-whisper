FROM nvidia/cuda:12.1.105-cudnn8-runtime-ubuntu22.04

WORKDIR /app

COPY worker.py .
COPY requirements.txt .

RUN apt-get update && apt-get install -y python3-pip ffmpeg && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir torch==2.2.0+cu121 torchvision --extra-index-url https://download.pytorch.org/whl/cu121
RUN pip install --no-cache-dir -r requirements.txt

ENV REDIS_HOST=redis

CMD ["python", "worker.py"]
