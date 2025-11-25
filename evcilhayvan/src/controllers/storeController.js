// src/controllers/storeController.js
import { validationResult } from "express-validator";
import Store from "../models/Store.js";
import Product from "../models/Product.js";
import User from "../models/User.js";
import { signToken } from "../utils/jwt.js";

function buildUserPayload(user) {
  return {
    id: user._id,
    name: user.name,
    email: user.email,
    city: user.city,
    role: user.role,
    avatarUrl: user.avatarUrl,
    about: user.about,
  };
}

export async function listStores(_req, res) {
  try {
    const stores = await Store.find({ isActive: true })
      .populate("owner", "name avatarUrl city role")
      .sort({ createdAt: -1 });

    return res.status(200).json({ ok: true, stores });
  } catch (err) {
    console.error("[listStores]", err);
    return res
      .status(500)
      .json({ message: "Mağaza listesi alınamadı", error: err.message });
  }
}

export async function listProducts(_req, res) {
  try {
    const products = await Product.find({ isActive: true })
      .populate({
        path: "store",
        select: "name logoUrl owner description isActive",
        match: { isActive: true },
        populate: { path: "owner", select: "name avatarUrl city role" },
      })
      .sort({ createdAt: -1 });

    const activeProducts = products.filter((p) => Boolean(p.store));

    return res.status(200).json({ ok: true, products: activeProducts });
  } catch (err) {
    console.error("[listProducts]", err);
    return res
      .status(500)
      .json({ message: "Ürün listesi alınamadı", error: err.message });
  }
}

export async function applySeller(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const userId = req.user.sub;
    const { storeName, description, logoUrl } = req.body || {};

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "Kullanıcı bulunamadı" });
    }

    let store = await Store.findOne({ owner: userId });

    if (!store) {
      store = await Store.create({
        owner: userId,
        name: storeName,
        description: description || "",
        logoUrl: logoUrl || "",
      });
    } else {
      store.name = storeName || store.name;
      store.description = description ?? store.description;
      store.logoUrl = logoUrl ?? store.logoUrl;
      store.isActive = true;
      await store.save();
    }

    if (user.role !== "seller") {
      user.role = "seller";
      await user.save();
    }

    const token = signToken(user);

    const populatedStore = await Store.findById(store._id).populate(
      "owner",
      "name avatarUrl city role"
    );

    return res
      .status(200)
      .json({ ok: true, token, user: buildUserPayload(user), store: populatedStore });
  } catch (err) {
    console.error("[applySeller]", err);
    return res
      .status(500)
      .json({ message: "Mağaza oluşturulamadı", error: err.message });
  }
}

export async function getMyStore(req, res) {
  try {
    const userId = req.user.sub;
    const store = await Store.findOne({ owner: userId }).populate(
      "owner",
      "name avatarUrl city"
    );

    if (!store) {
      return res
        .status(404)
        .json({ message: "Mağazanız bulunamadı. Önce başvuru yapın." });
    }

    return res.status(200).json({ ok: true, store });
  } catch (err) {
    console.error("[getMyStore]", err);
    return res
      .status(500)
      .json({ message: "Mağaza getirilemedi", error: err.message });
  }
}

export async function addProduct(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const userId = req.user.sub;
    const { title, description, price, photos, stock } = req.body || {};

    const store = await Store.findOne({ owner: userId });
    if (!store) {
      return res.status(404).json({ message: "Önce mağaza oluşturmalısınız" });
    }

    const product = await Product.create({
      store: store._id,
      title,
      description,
      price,
      photos: photos || [],
      stock: typeof stock === "number" ? stock : 0,
    });

    return res.status(201).json({ ok: true, product });
  } catch (err) {
    console.error("[addProduct]", err);
    return res
      .status(500)
      .json({ message: "Ürün eklenemedi", error: err.message });
  }
}

export async function getStoreProducts(req, res) {
  try {
    const { storeId } = req.params;

    const store = await Store.findById(storeId).populate(
      "owner",
      "name avatarUrl city"
    );
    if (!store) {
      return res.status(404).json({ message: "Mağaza bulunamadı" });
    }

    if (!store.isActive) {
      return res.status(403).json({ message: "Mağaza aktif değil" });
    }

    const products = await Product.find({ store: storeId, isActive: true }).sort({
      createdAt: -1,
    });

    return res.status(200).json({ ok: true, products });
  } catch (err) {
    console.error("[getStoreProducts]", err);
    return res
      .status(500)
      .json({ message: "Ürünler alınamadı", error: err.message });
  }
}

export async function getMyProducts(req, res) {
  try {
    const userId = req.user.sub;
    const store = await Store.findOne({ owner: userId });

    if (!store) {
      return res.status(404).json({ message: "Mağaza bulunamadı" });
    }

    const products = await Product.find({ store: store._id }).sort({ createdAt: -1 });
    return res.status(200).json({ ok: true, products });
  } catch (err) {
    console.error("[getMyProducts]", err);
    return res
      .status(500)
      .json({ message: "Ürünler alınamadı", error: err.message });
  }
}

export async function getStoreProfile(req, res) {
  try {
    const { storeId } = req.params;
    const store = await Store.findById(storeId).populate("owner", "name avatarUrl city");

    if (!store) {
      return res.status(404).json({ message: "Mağaza bulunamadı" });
    }

    return res.status(200).json({ ok: true, store });
  } catch (err) {
    console.error("[getStoreProfile]", err);
    return res
      .status(500)
      .json({ message: "Mağaza getirilemedi", error: err.message });
  }
}
