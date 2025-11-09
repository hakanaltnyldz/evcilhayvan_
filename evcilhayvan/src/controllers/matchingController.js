import mongoose from "mongoose";

import Pet from "../models/Pet.js";
import Conversation from "../models/Conversation.js";
import MatchRequest from "../models/MatchRequest.js";

const turkishSpeciesMap = {
  dog: "Köpek",
  cat: "Kedi",
  bird: "Kuş",
  fish: "Balık",
  rodent: "Kemirgen",
  other: "Diğer",
};

const turkishGenderMap = {
  male: "Erkek",
  female: "Dişi",
  unknown: "Bilinmiyor",
};

const reverseSpeciesMap = Object.fromEntries(
  Object.entries(turkishSpeciesMap).map(([key, value]) => [value.toLowerCase(), key])
);

const reverseGenderMap = Object.fromEntries(
  Object.entries(turkishGenderMap).map(([key, value]) => [value.toLowerCase(), key])
);

function normalizeEnum(value, reverseMap) {
  if (!value) return null;
  const lower = String(value).toLowerCase();
  return reverseMap[lower] ?? lower;
}

function formatSpecies(value) {
  const lower = String(value || "").toLowerCase();
  return turkishSpeciesMap[lower] ?? value ?? "";
}

function formatGender(value) {
  const lower = String(value || "").toLowerCase();
  return turkishGenderMap[lower] ?? value ?? "";
}

function toObjectId(id) {
  return new mongoose.Types.ObjectId(id);
}

function isValidCoordinates(location) {
  const coords = location?.coordinates;
  return (
    Array.isArray(coords) &&
    coords.length === 2 &&
    coords.every((num) => typeof num === "number" && !Number.isNaN(num)) &&
    !(coords[0] === 0 && coords[1] === 0)
  );
}

export async function getMatchingProfiles(req, res) {
  try {
    const userId = req.user.sub;
    const { species, gender, maxDistanceKm } = req.query;

    const normalizedSpecies = normalizeEnum(species, reverseSpeciesMap);
    const normalizedGender = normalizeEnum(gender, reverseGenderMap);
    const maxDistance = maxDistanceKm ? Number(maxDistanceKm) : null;

    const myPets = await Pet.find({ ownerId: userId, isActive: true }).select(
      "_id location"
    );

    const myLocationPet = myPets.find((pet) => isValidCoordinates(pet.location));
    const matchFilter = {
      ownerId: { $ne: toObjectId(userId) },
      isActive: true,
    };

    if (normalizedSpecies && normalizedSpecies !== "tümü") {
      matchFilter.species = normalizedSpecies;
    }
    if (normalizedGender && normalizedGender !== "tümü") {
      matchFilter.gender = normalizedGender;
    }

    const pipeline = [];
    if (myLocationPet) {
      const geoStage = {
        $geoNear: {
          near: {
            type: "Point",
            coordinates: myLocationPet.location.coordinates,
          },
          distanceField: "distanceMeters",
          spherical: true,
        },
      };
      if (maxDistance && Number.isFinite(maxDistance) && maxDistance > 0) {
        geoStage.$geoNear.maxDistance = maxDistance * 1000;
      }
      pipeline.push(geoStage);
    } else {
      pipeline.push({
        $addFields: {
          distanceMeters: 0,
        },
      });
    }

    pipeline.push({ $match: matchFilter });
    pipeline.push({ $sort: { createdAt: -1 } });

    pipeline.push({
      $lookup: {
        from: "users",
        localField: "ownerId",
        foreignField: "_id",
        as: "owner",
      },
    });
    pipeline.push({
      $unwind: {
        path: "$owner",
        preserveNullAndEmptyArrays: true,
      },
    });

    const rawPets = await Pet.aggregate(pipeline);

    const targetPetIds = rawPets.map((pet) => pet._id);

    const existingRequests = await MatchRequest.find({
      requester: userId,
      targetPet: { $in: targetPetIds },
    }).lean();

    const requestStatusMap = new Map(
      existingRequests.map((doc) => [String(doc.targetPet), doc.status])
    );

    const profiles = rawPets.map((pet) => {
      const rawDistance = (pet.distanceMeters || 0) / 1000;
      const distanceKm = Number(rawDistance.toFixed(2));
      const status = requestStatusMap.get(String(pet._id)) ?? null;

      return {
        id: String(pet._id),
        petId: String(pet._id),
        name: pet.name,
        species: formatSpecies(pet.species),
        breed: pet.breed || "Bilinmiyor",
        gender: formatGender(pet.gender),
        ageMonths: pet.ageMonths ?? 0,
        bio: pet.bio ?? "",
        images: pet.photos ?? [],
        distanceKm,
        hasPendingRequest: status === "pending",
        isMatched: status === "matched",
      };
    });

    const filteredProfiles =
      maxDistance && Number.isFinite(maxDistance) && maxDistance > 0
        ? profiles.filter((profile) => profile.distanceKm <= maxDistance)
        : profiles;

    res.json({ ok: true, profiles: filteredProfiles });
  } catch (err) {
    console.error("[getMatchingProfiles]", err);
    res.status(500).json({
      message: "Eşleşme profilleri alınamadı",
      error: err.message,
    });
  }
}

export async function sendMatchRequest(req, res) {
  try {
    const userId = req.user.sub;
    const { profileId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(profileId)) {
      return res.status(400).json({ message: "Geçersiz profil ID" });
    }

    const targetPet = await Pet.findById(profileId).populate(
      "ownerId",
      "name avatarUrl"
    );

    if (!targetPet || !targetPet.isActive) {
      return res.status(404).json({ message: "İlan bulunamadı" });
    }

    if (String(targetPet.ownerId._id) === String(userId)) {
      return res
        .status(400)
        .json({ message: "Kendi ilanınıza eşleşme isteği gönderemezsiniz" });
    }

    const existing = await MatchRequest.findOne({
      requester: userId,
      targetPet: targetPet._id,
    });

    if (existing) {
      if (existing.status === "matched") {
        return res.json({
          success: true,
          didMatch: true,
          message: "Bu ilanla zaten eşleştiniz.",
        });
      }

      return res.json({
        success: true,
        didMatch: false,
        message: "Eşleşme isteği zaten gönderildi.",
      });
    }

    const myPet = await Pet.findOne({ ownerId: userId, isActive: true });

    const created = await MatchRequest.create({
      requester: userId,
      requesterPet: myPet?._id,
      targetPet: targetPet._id,
      targetOwner: targetPet.ownerId._id,
      status: "pending",
    });

    const reciprocal = await MatchRequest.findOne({
      requester: targetPet.ownerId._id,
      targetOwner: userId,
      status: { $in: ["pending", "matched"] },
    });

    if (reciprocal) {
      created.status = "matched";
      reciprocal.status = "matched";
      await Promise.all([created.save(), reciprocal.save()]);

      const participants = [userId, String(targetPet.ownerId._id)];
      await Conversation.findOneAndUpdate(
        {
          participants: { $all: participants },
          relatedPet: targetPet._id,
        },
        {
          participants,
          relatedPet: targetPet._id,
          lastMessage: "Eşleşme isteği karşılıklı! Sohbete başlayın.",
        },
        { upsert: true, new: true }
      );

      return res.json({
        success: true,
        didMatch: true,
        message: "Harika! Karşılıklı eşleşme sağlandı.",
      });
    }

    return res.status(201).json({
      success: true,
      didMatch: false,
      message: "Eşleşme isteği gönderildi.",
    });
  } catch (err) {
    console.error("[sendMatchRequest]", err);
    res.status(500).json({
      message: "Eşleşme isteği gönderilemedi",
      error: err.message,
    });
  }
}
