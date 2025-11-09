// server.js
import "dotenv/config";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import mongoose from "mongoose";
import path from "path";
import { createServer } from "http";
import { Server as SocketIOServer } from "socket.io";

// Routes
import authRoutes from "./src/routes/authRoutes.js";
import petRoutes from "./src/routes/petRoutes.js";
import interactionRoutes from "./src/routes/interactionRoutes.js";
import messageRoutes from "./src/routes/messageRoutes.js";
import matchingRoutes from "./src/routes/matchingRoutes.js";

const app = express();
const httpServer = createServer(app);

// --- Socket.io ---
const io = new SocketIOServer(httpServer, {
  cors: {
    origin: "*",
    methods: ["GET","POST","PUT","DELETE","PATCH","OPTIONS"],
    allowedHeaders: ["Content-Type","Authorization"],
  },
});

// Middlewares
app.use(cors());
app.use(helmet());
app.use(morgan("dev"));
app.use(express.json({ limit: "2mb" }));

// Static
const __dirname = path.resolve(path.dirname(""));
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Health
app.get("/api/health", (_req, res) => res.json({ ok: true }));

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/pets", petRoutes);
app.use("/api/interactions", interactionRoutes);
app.use("/api/conversations", messageRoutes);
app.use("/api/matching", matchingRoutes);

// DB & Server
const PORT = process.env.PORT || 4000;
const MONGO_URI =
  process.env.MONGO_URI || "mongodb://127.0.0.1:27017/evcilhayvan";

mongoose
  .connect(MONGO_URI)
  .then(() => {
    console.log("✅ MongoDB connected");
    httpServer.listen(PORT, "0.0.0.0", () => {
      console.log(`🚀 Sunucu 0.0.0.0:${PORT} üzerinde çalışıyor.`);
    });
  })
  .catch((err) => {
    console.error("Mongo connection error:", err.message);
    process.exit(1);
  });

// ---------------- SOCKET HANDLERS (Flutter ile uyumlu) ----------------
io.on("connection", (socket) => {
  console.log("📱 Socket bağlandı:", socket.id);

  socket.on("joinRoom", (conversationId) => {
    if (!conversationId) return;
    socket.join(conversationId);
    console.log(`👥 ${socket.id} odasına katıldı => ${conversationId}`);
  });

  // Frontend 'sendMessage' emit ediyor
  socket.on("sendMessage", (payload) => {
    const { conversationId } = payload || {};
    if (!conversationId) return;
    // Frontend 'receiveMessage' dinliyor
    io.to(conversationId).emit("receiveMessage", payload);
  });

  socket.on("disconnect", () => {
    console.log("❌ Socket ayrıldı:", socket.id);
  });
});

export { io };
