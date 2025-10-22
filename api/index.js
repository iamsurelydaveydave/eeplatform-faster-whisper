import express from "express";
import multer from "multer";
import { createClient } from "redis";
import { randomUUID } from "crypto";

const app = express();
const upload = multer({ dest: "/app/shared/audio" });
const redis = createClient({ url: `redis://${process.env.REDIS_HOST}:6379` });

await redis.connect();

app.post("/transcribe", upload.single("audio"), async (req, res) => {
  const jobId = randomUUID();
  const filePath = req.file.path;

  await redis.lPush(
    "transcription_queue",
    JSON.stringify({ jobId, file_path: filePath })
  );
  res.json({ jobId, status: "queued" });
});

app.listen(8000, () => console.log("API running on port 8000"));
