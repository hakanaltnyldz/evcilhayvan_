import mongoose from "mongoose";

const PetSchema = new mongoose.Schema(
  {
    ownerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    name: { type: String, required: true, trim: true, maxlength: 80 },
    species: { type: String, enum: ["dog", "cat", "bird", "fish", "rodent", "other"], required: true },
    breed: { type: String, trim: true },
    gender: { type: String, enum: ["male", "female", "unknown"], default: "unknown" },
    ageMonths: { type: Number, min: 0, default: 0 },
    bio: { type: String, trim: true, maxlength: 500 },
    photos: { type: [String], default: [] },
    vaccinated: { type: Boolean, default: false },               // ← filtre için faydalı
    location: {
      type: { type: String, enum: ["Point"], default: "Point" },
      coordinates: { type: [Number], default: [0, 0] }
    },
    isActive: { type: Boolean, default: true }
  },
  { timestamps: true }
);

// Arama ve harita
PetSchema.index({ name: "text", bio: "text" }); // ← q için
PetSchema.index({ location: "2dsphere" });

export default mongoose.model("Pet", PetSchema);
