// src/routes/storeRoutes.js
import { Router } from "express";
import { body, param } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import {
  applySeller,
  getMyStore,
  addProduct,
  getStoreProducts,
  getMyProducts,
  getStoreProfile,
  listStores,
  listAllProducts,
} from "../controllers/storeController.js";

const router = Router();

router.post(
  "/apply",
  authRequired(),
  [
    body("storeName").notEmpty().withMessage("Mağaza adı gerekli"),
    body("description").optional().isString(),
    body("logoUrl").optional().isString(),
  ],
  applySeller
);

router.get("/me", authRequired(), getMyStore);

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

router.get("/products", listAllProducts);

router.get("/", listStores);

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

export default router;
