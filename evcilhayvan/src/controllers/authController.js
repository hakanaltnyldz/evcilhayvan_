// controllers/authController.js
import { validationResult } from "express-validator";
import User from "../models/User.js";
import { hashPassword, comparePassword } from "../utils/hash.js";
import { signToken } from "../utils/jwt.js";
import { sendEmail } from "../utils/mail.js";

// --- YENİ EKLENEN FONKSİYON: getAllUsers ---
/**
 * GET /api/auth/users
 * Diğer kullanıcıları listeler (Bağlan ekranı için)
 */
export async function getAllUsers(req, res) {
  try {
    const myId = req.user.sub; // Kendi ID'miz

    // 1. Veritabanından, kendi ID'miz DIŞINDAKİ herkesi bul
    // Sadece public olarak görünmesi gereken alanları seç ('select')
    const users = await User.find({ _id: { $ne: myId } })
      .select("name email city avatarUrl role createdAt")
      .sort({ createdAt: -1 }); // En yeni katılanlar en üstte

    // 2. Kullanıcı listesini döndür
    return res.status(200).json({ ok: true, users: users });

  } catch (err) {
    return res.status(500).json({ message: err.message || "Sunucu hatası" });
  }
}
// --- YENİ FONKSİYON BİTTİ ---


/* --- MEVCUT FONKSİYONLAR (Değişiklik Yok) --- */

export async function updateMe(req, res) { /* ... (kod aynı) ... */ 
  try {
    const { name, city, about } = req.body;
    const user = await User.findById(req.user.sub);
    if (!user) {
      return res.status(404).json({ message: "Kullanıcı bulunamadı" });
    }
    user.name = name || user.name;
    user.city = city || user.city;
    user.about = about || user.about;
    await user.save();
    const userResponse = {
      id: user._id, name: user.name, email: user.email,
      city: user.city, role: user.role, avatarUrl: user.avatarUrl,
      about: user.about,
    };
    return res.status(200).json({ ok: true, user: userResponse });
  } catch (err) {
    return res.status(500).json({ message: err.message || "Sunucu hatası" });
  }
}
export async function forgotPassword(req, res) { /* ... (kod aynı) ... */ 
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: "Bu e-posta ile kayıtlı kullanıcı bulunamadı" });
    }
    const resetCode = user.createPasswordResetToken();
    await user.save();
    try {
      const emailHtml = `<h1>Şifre Sıfırlama İsteği</h1><p>6 haneli doğrulama kodunuz:</p><h2 style="color: #333; letter-spacing: 2px;">${resetCode}</h2><p>Bu kod 10 dakika geçerlidir.</p>`;
      await sendEmail(user.email, "Şifreni Sıfırla", emailHtml);
      return res.status(200).json({ ok: true, message: "Şifre sıfırlama kodu e-postanıza gönderildi." });
    } catch (err) {
      user.passwordResetToken = undefined;
      user.passwordResetExpires = undefined;
      await user.save();
      console.error("Şifre sıfırlama e-postası gönderme hatası:", err);
      return res.status(500).json({ message: "E-posta gönderilemedi, lütfen tekrar deneyin." });
    }
  } catch (err) {
    return res.status(500).json({ message: err.message || "Sunucu hatası" });
  }
}
export async function resetPassword(req, res) { /* ... (kod aynı) ... */ 
  try {
    const { email, code, newPassword } = req.body;
    const user = await User.findOne({
      email: email,
      passwordResetToken: code,
      passwordResetExpires: { $gt: Date.now() }
    }).select("+passwordResetToken +passwordResetExpires");
    if (!user) {
      return res.status(400).json({ message: "Şifre sıfırlama kodu geçersiz veya süresi dolmuş." });
    }
    user.password = await hashPassword(newPassword);
    user.passwordResetToken = undefined;
    user.passwordResetExpires = undefined;
    await user.save();
    return res.status(200).json({ ok: true, message: "Şifreniz başarıyla güncellendi. Şimdi giriş yapabilirsiniz." });
  } catch (err) {
    return res.status(500).json({ message: err.message || "Sunucu hatası" });
  }
}
export async function register(req, res) { /* ... (kod aynı) ... */ 
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty())
      return res.status(400).json({ message: "Doğrulama", errors: errors.array() });
    const { name, email, password, city } = req.body;
    let exists = await User.findOne({ email });
    if (exists && !exists.isVerified) {
      await User.deleteOne({ email });
    } else if (exists) {
      return res.status(409).json({ message: "Email zaten kayıtlı" });
    }
    const user = new User({
      name, email, city,
      password: await hashPassword(password),
    });
    const verificationCode = user.createVerificationToken();
    await user.save();
    try {
      const emailHtml = `<h1>Evcil Hayvan Uygulamasına Hoş Geldin!</h1><p>Hesabını doğrulamak için 6 haneli kodun aşağıdadır:</p><h2 style="color: #333; letter-spacing: 2px;">${verificationCode}</h2><p>Bu kod 10 dakika geçerlidir.</p>`;
      await sendEmail(user.email, "Hesabını Doğrula", emailHtml);
    } catch (err) {
      console.error("Kayıt sonrası e-posta gönderme hatası:", err);
      return res.status(500).json({ message: "Kullanıcı oluşturuldu ancak doğrulama e-postası gönderilemedi." });
    }
    return res.status(201).json({
      ok: true,
      message: "Kayıt başarılı! Lütfen e-postanıza gönderilen doğrulama kodunu girin.",
      email: user.email 
    });
  } catch (err) {
    if (err?.code === 11000)
      return res.status(409).json({ message: "Email zaten kayıtlı" });
    return res.status(500).json({ message: err.message || "Sunucu hatası" });
  }
}
export async function verifyEmail(req, res) { /* ... (kod aynı) ... */ 
  try {
    const { email, code } = req.body;
    if (!email || !code) {
      return res.status(400).json({ message: "Email ve doğrulama kodu gerekli" });
    }
    const user = await User.findOne({ 
      email: email, 
      verificationToken: code,
      verificationTokenExpires: { $gt: Date.now() }
    }).select("+verificationToken +verificationTokenExpires");
    if (!user) {
      return res.status(400).json({ message: "Doğrulama kodu geçersiz veya süresi dolmuş." });
    }
    user.isVerified = true;
    user.verificationToken = undefined;
    user.verificationTokenExpires = undefined;
    await user.save();
    const token = signToken(user);
    return res.json({
      ok: true, token,
      user: {
        id: user._id, name: user.name, email: user.email,
        city: user.city, role: user.role, avatarUrl: user.avatarUrl,
      },
    });
  } catch (err) {
    return res.status(500).json({ message: err.message || "Sunucu hatası" });
  }
}
export async function login(req, res) { /* ... (kod aynı) ... */ 
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty())
      return res.status(400).json({ message: "Doğrulama", errors: errors.array() });
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ message: "Geçersiz bilgiler" });
    const ok = await comparePassword(password, user.password);
    if (!ok) return res.status(401).json({ message: "Geçersiz bilgiler" });
    if (!user.isVerified) {
      return res.status(403).json({ 
        message: "Hesabınız doğrulanmamış. Lütfen e-postanızı kontrol edin.",
        notVerified: true,
        email: user.email,
      });
    }
    const token = signToken(user);
    return res.json({
      ok: true, token,
      user: {
        id: user._id, name: user.name, email: user.email,
        city: user.city, role: user.role, avatarUrl: user.avatarUrl,
      },
    });
  } catch (err) {
    return res.status(500).json({ message: err.message || "Sunucu hatası" });
  }
}
export async function me(req, res) { /* ... (kod aynı) ... */ 
  const user = await User.findById(req.user.sub).select(
    "name email role city about avatarUrl"
  );
  return res.json({ ok: true, user });
}
export async function uploadAvatar(req, res) { /* ... (kod aynı) ... */ 
  try {
    if (!req.file) {
      return res.status(400).json({ message: "Dosya gerekli" });
    }
    const user = await User.findById(req.user.sub);
    if (!user) {
      return res.status(404).json({ message: "Kullanıcı bulunamadı" });
    }
    const publicPath = `/uploads/${req.file.filename}`;
    user.avatarUrl = publicPath;
    await user.save();
    return res.status(200).json({ 
      ok: true, url: publicPath,
      user: {
        id: user._id, name: user.name, email: user.email,
        city: user.city, role: user.role, avatarUrl: user.avatarUrl,
      },
    });
  } catch (err) {
    return res.status(500).json({ message: err.message || "Sunucu hatası" });
  }
}