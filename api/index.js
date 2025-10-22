import express from "express";
import multer from "multer";
import { createClient } from "redis";
import { randomUUID } from "crypto";
import dotenv from "dotenv";
import path from "path";
dotenv.config();

const REDIS_HOST = process.env.REDIS_HOST || "localhost";
const REDIS_PORT = process.env.REDIS_PORT || "6379";

const app = express();

// Allowed audio file types
const ALLOWED_AUDIO_TYPES = [
  "audio/mpeg",
  "audio/mp3",
  "audio/wav",
  "audio/wave",
  "audio/x-wav",
  "audio/ogg",
  "audio/webm",
  "audio/flac",
  "audio/aac",
  "audio/m4a",
  "audio/mp4",
  "video/mp4",
  "video/webm",
];

const ALLOWED_EXTENSIONS = [
  ".mp3",
  ".wav",
  ".ogg",
  ".webm",
  ".flac",
  ".aac",
  ".m4a",
  ".mp4",
];

// File filter for multer
const fileFilter = (req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();

  if (
    ALLOWED_AUDIO_TYPES.includes(file.mimetype) ||
    ALLOWED_EXTENSIONS.includes(ext)
  ) {
    cb(null, true);
  } else {
    cb(
      new Error(
        `Invalid file type. Allowed types: ${ALLOWED_EXTENSIONS.join(", ")}`
      ),
      false
    );
  }
};

const upload = multer({
  dest: "/app/shared/audio",
  fileFilter: fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB limit
  },
});

const redis = createClient({ url: `redis://${REDIS_HOST}:${REDIS_PORT}` });

await redis.connect();

app.post("/transcribe", upload.single("audio"), async (req, res) => {
  try {
    // Check if file was uploaded
    if (!req.file) {
      return res.status(400).json({
        error: "No audio file provided",
        status: "error",
      });
    }

    const jobId = randomUUID();
    const filePath = req.file.path;

    // Queue the job
    await redis.lPush(
      "transcription_queue",
      JSON.stringify({ jobId, file_path: filePath })
    );

    res.json({
      jobId,
      status: "queued",
      filename: req.file.originalname,
      size: req.file.size,
    });
  } catch (error) {
    console.error("Error in /transcribe:", error);
    res.status(500).json({
      error: error.message,
      status: "error",
    });
  }
});

app.get("/status/:jobId", async (req, res) => {
  try {
    const jobId = req.params.jobId;

    // Check if result exists
    const result = await redis.get(`job:${jobId}:result`);
    if (result) {
      return res.json(JSON.parse(result));
    }

    // Check if job status exists
    const status = await redis.get(`job:${jobId}:status`);
    if (status) {
      return res.json(JSON.parse(status));
    }

    // Job not found
    res.status(404).json({ status: "not_found", error: "Job not found" });
  } catch (error) {
    res.status(500).json({ status: "error", error: error.message });
  }
});

// Global error handler for multer and other errors
app.use((error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    if (error.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({
        error: "File too large. Maximum size is 100MB.",
        status: "error",
      });
    }
  }

  if (error.message.includes("Invalid file type")) {
    return res.status(400).json({
      error: error.message,
      status: "error",
    });
  }

  console.error("Unhandled error:", error);
  res.status(500).json({
    error: "Internal server error",
    status: "error",
  });
});

app.listen(8000, () => console.log("API running on port 8000"));
