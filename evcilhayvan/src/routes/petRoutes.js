// routes/petRoutes.js

import { Router } from "express";
import { body, param } from "express-validator";
import fs from "fs";
import path from "path";
import multer from "multer";

import { authRequired } from "../middlewares/auth.js";
import {
  createPet,
  myPets,
  updatePet,
  listPets,
  deletePet,
  getPet,
  uploadPetImage,
  getPetFeed // YENİ IMPORT
} from "../controllers/petController.js";

const router = Router();

/* ---------- Multer (uploads/) ---------- */
const uploadDir = path.join(process.cwd(), "uploads");
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => {
    const unique = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname || "");
    cb(null, unique + ext);
  }
});
const upload = multer({ storage });
/* ------------------------------------------- */

/* --- AUTH GEREKTİREN ÖZEL ROTALAR --- */

// YENİ AKILLI "FEED" ROTASI
// Bu, "/me" ve "/:id" rotalarından önce gelmeli
router.get(
  "/feed", 
  authRequired(), // Sadece giriş yapanlar akış alabilir
  getPetFeed
);

// "/me" rotası, parametreli "/:id" rotasından ÖNCE gelmeli
router.get("/me", authRequired(), myPets); 

router.post(
  "/",
  authRequired(),
  [ /* validation */
    body("name").notEmpty().withMessage("İsim gerekli"),
    body("species").isIn(["dog", "cat", "bird", "fish", "rodent", "other"]).withMessage("Geçersiz tür"),
    body("ageMonths").optional().isInt({ min: 0 }),
    body("photos").optional().isArray(),
    body("location.coordinates").optional().isArray({ min: 2, max: 2 })
  ],
  createPet
);

router.put(
  "/:id",
  authRequired(),
  [ /* validation */
    param("id").isMongoId(),
    body("species").optional().isIn(["dog", "cat", "bird", "fish", "rodent", "other"]),
    body("ageMonths").optional().isInt({ min: 0 }),
    body("location.coordinates").optional().isArray({ min: 2, max: 2 })
  ],
  updatePet
);

router.delete("/:id", authRequired(), [param("id").isMongoId()], deletePet);

// Image upload rotası
router.post(
  "/:id/images",
  authRequired(),
  [param("id").isMongoId()],
  upload.single("file"),
  uploadPetImage
);

/* --- PUBLIC ROTALAR --- */

// Public liste rotası ("/" ile başlar)
router.get("/", listPets); 

// Public detay rotası (PARAMETRELİ olduğu için en sonda olmalı)
router.get("/:id", [param("id").isMongoId()], getPet);

export default router;