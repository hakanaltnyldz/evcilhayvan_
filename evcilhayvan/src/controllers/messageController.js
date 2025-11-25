// src/controllers/messageController.js
import Conversation from "../models/Conversation.js";
import Message from "../models/Message.js";
import Interaction from "../models/Interaction.js";
import { io } from "../../server.js";

/**
 * Kullanıcının tüm sohbetleri
 * GET /api/conversations/me
 */
export async function getMyConversations(req, res) {
  try {
    const userId = req.user.sub;

    const conversations = await Conversation.find({
      participants: userId,
      deletedFor: { $ne: userId },
    })
      .populate("participants", "name avatarUrl email")
      .populate("relatedPet", "name photos")
      .sort({ updatedAt: -1 });

    res.status(200).json({ ok: true, conversations });
  } catch (err) {
    console.error("[getMyConversations HATA]", err);
    res
      .status(500)
      .json({ message: "Sohbetler alınamadı", error: err.message });
  }
}

/**
 * Bir sohbetin mesajları
 * GET /api/conversations/:conversationId
 */
export async function getMessages(req, res) {
  try {
    const { conversationId } = req.params;
    const userId = req.user.sub;

    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: userId,
      deletedFor: { $ne: userId },
    });
    if (!conversation) {
      return res
        .status(404)
        .json({ message: "Sohbet bulunamadı veya yetkiniz yok" });
    }

    const messages = await Message.find({ conversationId })
      .populate("sender", "name email avatarUrl")
      .sort({ createdAt: 1 });

    res.status(200).json({ ok: true, messages });
  } catch (err) {
    console.error("[getMessages HATA]", err);
    res
      .status(500)
      .json({ message: "Mesajlar alınamadı", error: err.message });
  }
}

/**
 * Mesaj gönder
 * POST /api/conversations/:conversationId
 */
export async function sendMessage(req, res) {
  try {
    const { conversationId } = req.params;
    const { text } = req.body;
    const senderId = req.user.sub;

    if (!text || !text.trim()) {
      return res.status(400).json({ message: "Mesaj içeriği boş olamaz" });
    }

    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: senderId,
    });
    if (!conversation) {
      return res
        .status(404)
        .json({ message: "Sohbet bulunamadı veya yetkiniz yok" });
    }

    // Yeni mesaj atıldığında silme listelerini temizleyip sohbeti tekrar görünür yap
    if (conversation.deletedFor && conversation.deletedFor.length > 0) {
      conversation.deletedFor = [];
    }

    const message = await Message.create({
      conversationId,
      sender: senderId,
      text: text.trim(),
    });

    conversation.lastMessage = text.trim();
    await conversation.save();

    const populated = await message.populate("sender", "name email avatarUrl");

    // Socket ile odaya yayınla (Flutter receiveMessage dinliyor)
    io.to(conversationId).emit("receiveMessage", {
      _id: populated._id,
      conversationId: populated.conversationId,
      text: populated.text,
      createdAt: populated.createdAt,
      sender: {
        _id: populated.sender._id,
        name: populated.sender.name,
        email: populated.sender.email,
        avatarUrl: populated.sender.avatarUrl,
      },
    });

    res.status(201).json({ ok: true, message: populated });
  } catch (err) {
    console.error("[sendMessage HATA]", err);
    res
      .status(500)
      .json({ message: "Mesaj gönderilemedi", error: err.message });
  }
}

/**
 * Sohbet yarat veya mevcutu getir (Community/DM)
 * POST /api/conversations
 * body: { participantId: string, relatedPetId?: string }
 */
export async function createOrGetConversation(req, res) {
  try {
    const userId = req.user.sub;
    const { participantId, relatedPetId } = req.body || {};

    if (!participantId) {
      return res.status(400).json({ message: "participantId gerekli" });
    }
    if (participantId === userId) {
      return res
        .status(400)
        .json({ message: "Kendinizle sohbet başlatamazsınız" });
    }

    // Aynı ilan üzerinden ise eşsiz; ilan yoksa (community) relatedPet=null eşsiz
    const query = {
      participants: { $all: [userId, participantId] },
      relatedPet: relatedPetId || null,
    };

    let conversation = await Conversation.findOne(query);

    if (!conversation) {
      if (relatedPetId) {
        const iLikedPet = await Interaction.exists({
          fromUser: userId,
          toPet: relatedPetId,
          type: "like",
        });

        const theyLikedOneOfMine = await Interaction.exists({
          fromUser: participantId,
          toPetOwner: userId,
          type: "like",
        });

        if (!iLikedPet || !theyLikedOneOfMine) {
          return res.status(403).json({
            message: "Bu ilan için henüz eşleşmediniz. Önce karşılıklı beğeni sağlayın.",
          });
        }
      }

      conversation = await Conversation.create({
        participants: [userId, participantId],
        relatedPet: relatedPetId || null,
        lastMessage: relatedPetId
            ? "Eşleşme sağlandı! İlk mesajı gönderin."
            : "",
      });
    }

    // Silinmiş olsa bile yeniden başlatırken görünür hale getir
    if (conversation.deletedFor && conversation.deletedFor.length > 0) {
      conversation.deletedFor = [];
      await conversation.save();
    }

    const populated = await Conversation.findById(conversation._id)
      .populate("participants", "name avatarUrl email")
      .populate("relatedPet", "name photos");

    res.status(200).json({ ok: true, conversation: populated });
  } catch (err) {
    console.error("[createOrGetConversation HATA]", err);
    res
      .status(500)
      .json({ message: "Sohbet başlatılamadı", error: err.message });
  }
}

export async function deleteConversation(req, res) {
  try {
    const { conversationId } = req.params;
    const userId = req.user.sub;

    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: userId,
    });

    if (!conversation) {
      return res
        .status(404)
        .json({ message: "Sohbet bulunamadı veya yetkiniz yok" });
    }

    const alreadyDeleted = (conversation.deletedFor || []).some(
      (id) => id.toString() === userId
    );

    if (!alreadyDeleted) {
      conversation.deletedFor.push(userId);
      await conversation.save();
    }

    res.status(200).json({ ok: true, softDeleted: true });
  } catch (err) {
    console.error("[deleteConversation HATA]", err);
    res
      .status(500)
      .json({ message: "Sohbet silinemedi", error: err.message });
  }
}
