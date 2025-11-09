// src/controllers/interactionController.js
import Interaction from "../models/Interaction.js";
import Pet from "../models/Pet.js";
import Conversation from "../models/Conversation.js";

// Eşleşme kontrolü + gerekli konuşmaları hazırla (ilan bazlı)
async function checkForMatch(reqUser, likedPet) {
  const myPets = await Pet.find({ ownerId: reqUser.sub }).select("_id");
  if (!myPets.length) return { match: false };

  const myPetIds = myPets.map((p) => p._id);

  const matchInteraction = await Interaction.findOne({
    fromUser: likedPet.ownerId._id,
    toPet: { $in: myPetIds },
    type: "like",
  }).populate("toPet");

  if (!matchInteraction) return { match: false };

  try {
    // Ben -> onun ilanı
    await Conversation.findOneAndUpdate(
      {
        relatedPet: likedPet._id,
        participants: { $all: [reqUser.sub, likedPet.ownerId._id] },
      },
      {
        participants: [reqUser.sub, likedPet.ownerId._id],
        relatedPet: likedPet._id,
        lastMessage: "Eşleştiniz! Sohbeti başlatın.",
      },
      { upsert: true, new: true }
    );

    // O -> benim ilanım (isteğe bağlı; karşılık için)
    await Conversation.findOneAndUpdate(
      {
        relatedPet: matchInteraction.toPet._id,
        participants: { $all: [reqUser.sub, likedPet.ownerId._id] },
      },
      {
        participants: [reqUser.sub, likedPet.ownerId._id],
        relatedPet: matchInteraction.toPet._id,
        lastMessage: "Eşleştiniz! Sohbeti başlatın.",
      },
      { upsert: true, new: true }
    );
  } catch (e) {
    console.error("[MATCH] Sohbet odası oluşturulurken hata:", e);
  }

  return { match: true, matchedWithUser: likedPet.ownerId };
}

export async function likePet(req, res) {
  try {
    const fromUserId = req.user.sub;
    const { petId } = req.params;

    const likedPet = await Pet.findById(petId).populate(
      "ownerId",
      "name avatarUrl"
    );
    if (!likedPet) return res.status(404).json({ message: "İlan bulunamadı" });

    if (String(likedPet.ownerId._id) === String(fromUserId)) {
      return res
        .status(400)
        .json({ message: "Kendi ilanınızı beğenemezsiniz" });
    }

    const existing = await Interaction.findOne({
      fromUser: fromUserId,
      toPet: petId,
    });

    if (!existing) {
      await Interaction.create({
        fromUser: fromUserId,
        toPet: petId,
        toPetOwner: likedPet.ownerId._id,
        type: "like",
      });
    }

    const { match, matchedWithUser } = await checkForMatch(req.user, likedPet);

    // Eğer eşleştiyse ilgili konuşmayı çek
    let conversationId = null;
    if (match) {
      const convo = await Conversation.findOne({
        participants: { $all: [fromUserId, likedPet.ownerId._id] },
        relatedPet: likedPet._id,
      });
      if (convo) conversationId = String(convo._id);
    }

    res.status(existing ? 200 : 201).json({
      ok: true,
      type: "like",
      match,
      matchedWith: matchedWithUser,
      conversationId,
    });
  } catch (err) {
    console.error("[likePet HATA]", err);
    res.status(500).json({ message: "İşlem başarısız", error: err.message });
  }
}

export async function passPet(req, res) {
  try {
    const fromUserId = req.user.sub;
    const { petId } = req.params;

    const petToPass = await Pet.findById(petId);
    if (!petToPass) return res.status(404).json({ message: "İlan bulunamadı" });
    if (String(petToPass.ownerId) === String(fromUserId)) {
      return res
        .status(400)
        .json({ message: "Kendi ilanınızı geçemezsiniz" });
    }

    const exists = await Interaction.findOne({ fromUser: fromUserId, toPet: petId });
    if (exists) {
      return res
        .status(409)
        .json({ message: "Bu ilanla zaten etkileşime girdiniz" });
    }

    await Interaction.create({
      fromUser: fromUserId,
      toPet: petId,
      toPetOwner: petToPass.ownerId,
      type: "pass",
    });

    res.status(201).json({ ok: true, type: "pass", match: false });
  } catch (err) {
    console.error("[passPet HATA]", err);
    res.status(500).json({ message: "İşlem başarısız", error: err.message });
  }
}
