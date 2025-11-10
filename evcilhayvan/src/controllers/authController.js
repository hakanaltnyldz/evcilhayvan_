// controllers/authController.js
import crypto from "crypto";
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

function sendAuthSuccess(res, user, status = 200) {
  const token = signToken(user);
  return res.status(status).json({
    ok: true,
    token,
    user: buildUserPayload(user),
  });
}

export async function loginWithGoogle(req, res) {
  try {
    const { idToken } = req.body || {};

    if (!idToken) {
      return res.status(400).json({ message: "Google idToken gerekli" });
    }

    const tokenInfoResponse = await fetch(
      `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`
    );

    if (!tokenInfoResponse.ok) {
      return res
        .status(401)
        .json({ message: "Geçersiz Google oturum bilgisi" });
    }

    const payload = await tokenInfoResponse.json();
    const audience = process.env.GOOGLE_CLIENT_ID;

    if (audience && payload.aud !== audience) {
      return res.status(401).json({ message: "Google istemcisi doğrulanamadı" });
    }

    if (payload.email_verified !== "true" && payload.email_verified !== true) {
      return res
        .status(401)
        .json({ message: "Google e-postası doğrulanmamış" });
    }

    const email = payload.email?.toLowerCase();
    if (!email) {
      return res
        .status(400)
        .json({ message: "Google e-postasına erişilemedi" });
    }

    let user = await User.findOne({ email });
    const displayName = payload.name?.trim() || email.split("@")[0];
    const avatarUrl = payload.picture;

    if (!user) {
      const randomPassword = crypto.randomBytes(32).toString("hex");
      user = new User({
        name: displayName,
        email,
        password: await hashPassword(randomPassword),
        avatarUrl,
        isVerified: true,
      });
    } else {
      user.name = user.name || displayName;
      user.isVerified = true;
      if (!user.avatarUrl && avatarUrl) {
        user.avatarUrl = avatarUrl;
      }
    }

    await user.save();

    return sendAuthSuccess(res, user);
  } catch (err) {
    console.error("[loginWithGoogle]", err);
    return res
      .status(500)
      .json({ message: "Google ile giriş yapılamadı", error: err.message });
  }
}

export async function loginWithFacebook(req, res) {
  try {
    const { accessToken } = req.body || {};
    if (!accessToken) {
      return res
        .status(400)
        .json({ message: "Facebook accessToken gerekli" });
    }

    const appId = process.env.FACEBOOK_APP_ID;
    const appSecret = process.env.FACEBOOK_APP_SECRET;

    if (appId && appSecret) {
      const debugResponse = await fetch(
        `https://graph.facebook.com/debug_token?input_token=${encodeURIComponent(
          accessToken
        )}&access_token=${appId}|${appSecret}`
      );

      const debugJson = await debugResponse.json();
      const isValid = debugJson?.data?.is_valid;
      if (!isValid) {
        return res
          .status(401)
          .json({ message: "Facebook oturumu doğrulanamadı" });
      }
    }

    const profileResponse = await fetch(
      `https://graph.facebook.com/me?fields=id,name,email,picture.type(large)&access_token=${encodeURIComponent(
        accessToken
      )}`
    );

    if (!profileResponse.ok) {
      return res
        .status(401)
        .json({ message: "Facebook profiline erişilemedi" });
    }

    const profile = await profileResponse.json();
    const email = profile.email?.toLowerCase();

    if (!email) {
      return res.status(400).json({
        message:
          "Facebook hesabınız e-posta paylaşmadı. Lütfen e-posta izinlerini verin.",
      });
    }

    let user = await User.findOne({ email });
    const displayName = profile.name?.trim() || email.split("@")[0];
    const avatarUrl = profile.picture?.data?.url;

    if (!user) {
      const randomPassword = crypto.randomBytes(32).toString("hex");
      user = new User({
        name: displayName,
        email,
        password: await hashPassword(randomPassword),
        avatarUrl,
        isVerified: true,
      });
    } else {
      user.name = user.name || displayName;
      user.isVerified = true;
      if (!user.avatarUrl && avatarUrl) {
        user.avatarUrl = avatarUrl;
      }
    }

    await user.save();

    return sendAuthSuccess(res, user);
  } catch (err) {
    console.error("[loginWithFacebook]", err);
    return res.status(500).json({
      message: "Facebook ile giriş yapılamadı",
      error: err.message,
    });
  }
}


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