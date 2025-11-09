import { Router } from "express";

import { authRequired } from "../middlewares/auth.js";
import {
  getMatchingProfiles,
  sendMatchRequest,
} from "../controllers/matchingController.js";

const router = Router();

router.use(authRequired());

router.get("/profiles", getMatchingProfiles);
router.post("/request/:profileId", sendMatchRequest);

export default router;
