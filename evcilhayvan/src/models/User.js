// models/User.js
import mongoose from "mongoose";
import crypto from "crypto"; 

const UserSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 80 },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, required: true },
    role: { type: String, enum: ["user", "admin", "seller"], default: "user" },
    city: { type: String, trim: true },
    about: { type: String, trim: true, maxlength: 500 },
    avatarUrl: { type: String, trim: true },
    fcmTokens: { type: [String], default: [] },

    // E-posta Doğrulama Alanları (Zaten vardı)
    isVerified: {
      type: Boolean,
      default: false,
    },
    verificationToken: {
      type: String,
      select: false,
    },
    verificationTokenExpires: {
      type: Date,
      select: false,
    },
    
    // --- YENİ EKLENEN ŞİFRE SIFIRLAMA ALANLARI ---
    passwordResetToken: {
      type: String,
      select: false, // Bu alanı da sorgularda gizle
    },
    passwordResetExpires: {
      type: Date,
      select: false,
    },
    // --- BİTTİ ---

  },
  { timestamps: true }
);

UserSchema.index({ email: 1 }, { unique: true });

// E-posta doğrulama kodu üreten metod (Zaten vardı)
UserSchema.methods.createVerificationToken = function () {
  const code = Math.floor(100000 + Math.random() * 900000).toString(); 
  this.verificationToken = code;
  this.verificationTokenExpires = Date.now() + 10 * 60 * 1000; // 10 dakika
  return code;
};

// --- YENİ EKLENEN ŞİFRE SIFIRLAMA KODU ÜRETEN METOD ---
UserSchema.methods.createPasswordResetToken = function () {
  const code = Math.floor(100000 + Math.random() * 900000).toString(); 
  this.passwordResetToken = code;
  this.passwordResetExpires = Date.now() + 10 * 60 * 1000; // 10 dakika
  return code;
};
// --- METOD BİTTİ ---

export default mongoose.model("User", UserSchema);