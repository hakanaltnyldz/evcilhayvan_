// src/routes/storeRoutes.js
import { Router } from "express";
import { body, param } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import {
  addProduct,
  applySeller,
  getMyProducts,
  getMyStore,
  getStoreProducts,
  getStoreProfile,
  listProducts,
  listStores,
} from "../controllers/storeController.js";

const router = Router();

// Public keşif uçları
router.get("/discover", listStores);
router.get("/feed", listProducts);

// Mağaza detay ve ürünleri (auth opsiyonel)
router.get(
  "/:storeId/products",
  [param("storeId").isMongoId().withMessage("Geçersiz mağaza ID")],
  getStoreProducts
);

router.get(
  "/:storeId",
  [param("storeId").isMongoId().withMessage("Geçersiz mağaza ID")],
  getStoreProfile
);

// Bu noktadan sonrası için kimlik doğrulama zorunlu
router.use(authRequired());

router.post(
  "/apply",
  [
    body("storeName").notEmpty().withMessage("Mağaza adı gerekli"),
    body("description").optional().isString(),
    body("logoUrl").optional().isString(),
  ],
  applySeller
);

router.get("/me", getMyStore);

router.post(
  "/me/products",
  authRequired(["seller", "admin"]),
  [
    body("title").notEmpty().withMessage("Ürün başlığı gerekli"),
    body("price").isFloat({ min: 0 }).withMessage("Fiyat 0'dan küçük olamaz"),
    body("description").optional().isString(),
    body("photos").optional().isArray(),
    body("stock").optional().isInt({ min: 0 }),
  ],
  addProduct
);

router.get(
  "/me/products",
  authRequired(["seller", "admin"]),
  getMyProducts
);

export default router;
