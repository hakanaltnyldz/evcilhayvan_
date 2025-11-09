import mongoose from "mongoose";

const { Schema } = mongoose;

const matchRequestSchema = new Schema(
  {
    requester: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    requesterPet: {
      type: Schema.Types.ObjectId,
      ref: "Pet",
    },
    targetPet: {
      type: Schema.Types.ObjectId,
      ref: "Pet",
      required: true,
      index: true,
    },
    targetOwner: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    status: {
      type: String,
      enum: ["pending", "matched", "declined"],
      default: "pending",
      index: true,
    },
  },
  { timestamps: true }
);

matchRequestSchema.index({ requester: 1, targetPet: 1 }, { unique: true });

export default mongoose.model("MatchRequest", matchRequestSchema);
