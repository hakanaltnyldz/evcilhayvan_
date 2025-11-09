// src/routes/messageRoutes.js
import { Router } from "express";
import { body, param } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import {
  getMyConversations,
  getMessages,
  sendMessage,
  createOrGetConversation,
} from "../controllers/messageController.js";

const router = Router();

router.use(authRequired());

// liste
router.get("/me", getMyConversations);

// bir sohbetin mesajları
router.get(
  "/:conversationId",
  [param("conversationId").isMongoId().withMessage("Geçersiz Sohbet ID")],
  getMessages
);

// mesaj gönder
router.post(
  "/:conversationId",
  [
    param("conversationId").isMongoId().withMessage("Geçersiz Sohbet ID"),
    body("text").notEmpty().withMessage("Mesaj içeriği gerekli"),
  ],
  sendMessage
);

// community/DM: participantId ile yarat/çek
router.post(
  "/",
  [body("participantId").isMongoId().withMessage("participantId gerekli")],
  createOrGetConversation
);

export default router;
