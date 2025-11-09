// middlewares/auth.js

import { verifyToken } from "../utils/jwt.js";

export function authRequired(allowedRoles = []) {
  return (req, res, next) => {
    // --- YENİ LOGLAMA EKLENDİ ---
    console.log(`[Auth Middleware] İstek geldi: ${req.method} ${req.path}`);
    // --- LOGLAMA BİTTİ ---
    try {
      const hdr = req.headers.authorization || "";
      const token = hdr.startsWith("Bearer ") ? hdr.slice(7) : null;

      // --- YENİ LOGLAMA EKLENDİ ---
      console.log(`[Auth Middleware] Gelen Token: ${token ? token.substring(0, 15) + '...' : 'Yok'}`);
      // --- LOGLAMA BİTTİ ---

      if (!token) {
        console.error("[Auth Middleware] HATA: Token Gerekli");
        return res.status(401).json({ message: "Token gerekli" });
      }

      const payload = verifyToken(token); // { sub, role, ... }

      // --- YENİ LOGLAMA EKLENDİ ---
      console.log(`[Auth Middleware] Token Payload'u:`, payload);
      // --- LOGLAMA BİTTİ ---
      
      req.user = payload; 
      
      if (allowedRoles.length === 0) {
        console.log(`[Auth Middleware] Rol kontrolü GEREKMİYOR. Devam ediliyor.`);
        return next(); 
      }

      console.log(`[Auth Middleware] Gerekli Roller: ${allowedRoles}, Kullanıcının Rolü: ${payload.role}`);
      if (payload.role && allowedRoles.includes(payload.role)) {
        console.log(`[Auth Middleware] Rol UYGUN. Devam ediliyor.`);
        return next(); 
      }
      
      console.error("[Auth Middleware] HATA: Yetki Yok");
      return res.status(403).json({ 
        message: "Erişim reddedildi. Bu işlem için yetkiniz yok." 
      });

    } catch (err) {
      // --- YENİ LOGLAMA EKLENDİ ---
      console.error("[Auth Middleware] HATA:", err.message);
      // --- LOGLAMA BİTTİ ---
      return res.status(401).json({ message: `Geçersiz veya süresi dolmuş token: ${err.message}` });
    }
  };
}