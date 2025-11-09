// controllers/petController.js

import { validationResult } from "express-validator";
import fs from "fs";
import path from "path";
import Pet from "../models/Pet.js";
import Interaction from "../models/Interaction.js"; // YENİ IMPORT
import mongoose from "mongoose";

// --- YENİ EKLENEN AKILLI AKIŞ (FEED) FONKSİYONU ---
/**
 * GET /api/pets/feed
 * Kullanıcının henüz etkileşime girmediği ve
 * kendisine ait olmayan ilanları getirir.
 */
export async function getPetFeed(req, res) {
  try {
    const userId = req.user.sub;
    const { page = 1, limit = 10 } = req.query;

    // 1. Kullanıcının zaten etkileşime girdiği (like/pass) ilanların ID'lerini bul
    const interactions = await Interaction.find({ fromUser: userId }).select('toPet');
    const interactedPetIds = interactions.map(interaction => interaction.toPet);

    // 2. Filtre oluştur:
    const filter = {
      isActive: true,
      ownerId: { $ne: userId }, // Bana ait olmayanlar
      _id: { $nin: interactedPetIds }, // Etkileşime girmediklerim
    };

    // 3. Veritabanından bu filtreye uygun ilanları çek
    const skip = (Number(page) - 1) * Number(limit);
    const [items, total] = await Promise.all([
      Pet.find(filter)
        .populate('ownerId', 'name avatarUrl') // Sahip bilgisini ekle
        .sort({ createdAt: -1 }) // Şimdilik en yeniye göre
        .skip(skip)
        .limit(Number(limit)),
      Pet.countDocuments(filter),
    ]);

    return res.json({
      ok: true,
      items,
      page: Number(page),
      limit: Number(limit),
      total,
      hasMore: skip + items.length < total,
    });

  } catch (err) {
    console.error("[getPetFeed HATA]", err);
    res.status(500).json({ message: "Akış yüklenemedi", error: err.message });
  }
}
// --- YENİ FONKSİYON BİTTİ ---


/* --- MEVCUT FONKSİYONLAR (Değişiklik yok) --- */

/** POST /api/pets (create) */
export async function createPet(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty())
    return res.status(400).json({ message: "Doğrulama", errors: errors.array() });
  const ownerId = req.user.sub;
  const body = { ...req.body, ownerId };
  if (body.location?.coordinates?.length === 2) {
    body.location = {
      type: "Point",
      coordinates: body.location.coordinates.map(Number),
    };
  } else {
    delete body.location;
  }
  let pet = await Pet.create(body);
  pet = await pet.populate('ownerId', 'name avatarUrl');
  return res.status(201).json({ ok: true, pet });
}

/** GET /api/pets/me (list my pets) */
export async function myPets(req, res) {
  console.log(`[myPets Controller] İstek geldi.`);
  console.log(`[myPets Controller] req.user:`, req.user);
  try {
    if (!req.user || !req.user.sub) {
      console.error("[myPets Controller] HATA: req.user veya req.user.sub bulunamadı!");
      return res.status(401).json({ message: "Geçersiz token veya kullanıcı kimliği" });
    }
    const ownerId = req.user.sub;
    console.log(`[myPets Controller] Sorgulanacak ownerId: ${ownerId}`);
    if (!mongoose.Types.ObjectId.isValid(ownerId)) {
      console.error("[myPets Controller] HATA: Geçersiz ObjectId formatı!");
      return res.status(400).json({ message: "Geçersiz kullanıcı ID formatı" });
    }
    console.log(`[myPets Controller] Pet.find sorgusu çalıştırılıyor...`);
    const pets = await Pet.find({ ownerId })
      .populate('ownerId', 'name avatarUrl')
      .sort({ createdAt: -1 });
    console.log(`[myPets Controller] ${pets.length} adet ilan bulundu.`);
    return res.json({ ok: true, pets });
  } catch (err) {
    console.error("[myPets Controller] BEKLENMEDİK HATA:", err);
    return res.status(500).json({ message: "İlanlar alınırken sunucu hatası oluştu", error: err.message });
  }
}

/** PUT /api/pets/:id (update mine OR admin update) */
export async function updatePet(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty())
    return res.status(400).json({ message: "Doğrulama", errors: errors.array() });
  const { id } = req.params;
  const filter = { _id: id };
  if (req.user.role !== 'admin') {
    filter.ownerId = req.user.sub;
  }
  const update = { ...req.body };
  if (update.location?.coordinates?.length === 2) {
    update.location = {
      type: "Point",
      coordinates: update.location.coordinates.map(Number),
    };
  } else if (update.location) {
    delete update.location;
  }
  const pet = await Pet.findOneAndUpdate(filter, update, { new: true })
    .populate('ownerId', 'name avatarUrl'); 
  if (!pet) return res.status(404).json({ message: "Pet bulunamadı veya bu işlem için yetkiniz yok" });
  return res.json({ ok: true, pet });
}

/** PUBLIC: GET /api/pets (filtre + sayfalama) */
export async function listPets(req, res) {
  const { species, vaccinated, q, page = 1, limit = 10 } = req.query;
  const filter = { isActive: true };
  if (species) filter.species = species;
  if (typeof vaccinated !== "undefined") filter.vaccinated = vaccinated === "true";
  if (q) {
    filter.$text = { $search: String(q) };
  }
  const skip = (Number(page) - 1) * Number(limit);
  const [items, total] = await Promise.all([
    Pet.find(filter)
      .populate('ownerId', 'name avatarUrl') 
      .sort(q ? { score: { $meta: "textScore" } } : { createdAt: -1 })
      .skip(skip)
      .limit(Number(limit)),
    Pet.countDocuments(filter),
  ]);
  return res.json({
    ok: true,
    items,
    page: Number(page),
    limit: Number(limit),
    total,
    hasMore: skip + items.length < total,
  });
}

/** PUBLIC: GET /api/pets/:id (detay) */
export async function getPet(req, res) {
  const pet = await Pet.findById(req.params.id)
    .populate('ownerId', 'name avatarUrl');
  if (!pet || !pet.isActive) return res.status(404).json({ message: "Pet bulunamadı" });
  return res.json({ ok: true, pet });
}

/** OWNED: DELETE /api/pets/:id (silme) */
export async function deletePet(req, res) {
  const { id } = req.params;
  const filter = { _id: id };
  if (req.user.role !== 'admin') {
    filter.ownerId = req.user.sub;
  }
  const pet = await Pet.findOneAndDelete(filter);
  if (!pet) return res.status(404).json({ message: "Pet bulunamadı veya bu işlem için yetkiniz yok" });
  return res.json({ ok: true });
}

/** OWNED: POST /api/pets/:id/images (form-data: file) */
export async function uploadPetImage(req, res) {
  const { id } = req.params;
  const filter = { _id: id };
  if (req.user.role !== 'admin') {
    filter.ownerId = req.user.sub;
  }
  const pet = await Pet.findOne(filter);
  if (!pet) return res.status(404).json({ message: "Pet bulunamadı veya bu işlem için yetkiniz yok" });
  if (!req.file) return res.status(400).json({ message: "Dosya gerekli" });
  const publicPath = `/uploads/${req.file.filename}`;
  pet.photos = [...(pet.photos || []), publicPath];
  await pet.save();
  return res.status(201).json({ ok: true, url: publicPath, photos: pet.photos });
}