// src/models/Conversation.js
import mongoose from "mongoose";
const { Schema } = mongoose;

const conversationSchema = new Schema(
  {
    participants: [
      {
        type: Schema.Types.ObjectId,
        ref: "User",
        required: true,
      },
    ],
    // İLAN ÜZERİNDEN başlayan sohbetlerde dolu olur, community/DM için boş olabilir.
    relatedPet: {
      type: Schema.Types.ObjectId,
      ref: "Pet",
      required: false, // <-- optional
      default: null,
    },
    lastMessage: {
      type: String,
      default: "",
    },
  },
  { timestamps: true }
);

// Aynı ilan + aynı iki kişi için tek kayıt
conversationSchema.index({ relatedPet: 1, participants: 1 });

export default mongoose.model("Conversation", conversationSchema);
