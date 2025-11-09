// routes/authRoutes.js
import { Router } from "express";
import { body } from "express-validator";
import fs from "fs";
import path from "path";
import multer from "multer";

import { 
  register, login, me, 
  uploadAvatar, verifyEmail,
  forgotPassword, resetPassword,
  updateMe,
  getAllUsers // YENİ IMPORT
} from "../controllers/authController.js";
import { authRequired } from "../middlewares/auth.js";

const router = Router();

/* ---------- Multer (Avatar Upload) ---------- */
const uploadDir = path.join(process.cwd(), "uploads");
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => {
    const unique = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname || "");
    cb(null, "avatar-" + unique + ext);
  }
});
const upload = multer({ storage });
/* ------------------------------------------- */

// === KAYIT / GİRİŞ / SIFIRLAMA ===
router.post("/register", [
  body("name").notEmpty().withMessage("İsim gerekli"),
  body("email").isEmail().withMessage("Geçerli email gerekli"),
  body("password").isLength({ min: 6 }).withMessage("Şifre min 6 karakter olmalı"),
], register);

router.post("/verify-email", [
  body("email").isEmail().withMessage("Geçerli email gerekli"),
  body("code").isLength({ min: 6, max: 6 }).withMessage("Doğrulama kodu 6 haneli olmalı"),
], verifyEmail);

router.post("/login", [
  body("email").isEmail().withMessage("Geçerli email gerekli"),
  body("password").notEmpty().withMessage("Şifre gerekli"),
], login);

router.post("/forgot-password", [
  body("email").isEmail().withMessage("Geçerli email gerekli"),
], forgotPassword);

router.post("/reset-password", [
  body("email").isEmail().withMessage("Geçerli email gerekli"),
  body("code").isLength({ min: 6, max: 6 }).withMessage("Doğrulama kodu 6 haneli olmalı"),
  body("newPassword").isLength({ min: 6 }).withMessage("Yeni şifre min 6 karakter olmalı"),
], resetPassword);

// === GİRİŞ GEREKTİREN İŞLEMLER ===
router.get("/me", authRequired(), me);

router.put("/me", authRequired(), [
    body("name").optional().notEmpty().withMessage("İsim boş olamaz"),
    body("city").optional().trim(),
    body("about").optional().trim(),
  ], updateMe
);

router.post(
  "/avatar",
  authRequired(),
  upload.single("avatar"),
  uploadAvatar
);

// --- YENİ EKLENEN KULLANICI LİSTELEME ROTASI ---
// (Bağlan ekranı için)
router.get(
  "/users",
  authRequired(), // Sadece giriş yapanlar
  getAllUsers
);
// --- ROTA BİTTİ ---

export default router;