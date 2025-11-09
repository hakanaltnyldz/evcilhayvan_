// utils/mail.js
import sgMail from "@sendgrid/mail";

// API anahtarını .env dosyasından al
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

/**
 * SendGrid kullanarak e-posta gönderen fonksiyon
 * @param {string} to - Alıcının e-posta adresi
 * @param {string} subject - E-postanın konusu
 * @param {string} html - E-postanın HTML içeriği
 */
export async function sendEmail(to, subject, html) {
  const msg = {
    to: to,
    from: process.env.SENDER_EMAIL, // .env'de tanımladığın doğrulanan adres
    subject: subject,
    html: html,
  };

  try {
    await sgMail.send(msg);
    console.log(`[Mail] E-posta başarıyla gönderildi: ${to}`);
  } catch (error) {
    console.error("[Mail] E-posta gönderme hatası:", error);
    if (error.response) {
      // SendGrid'den gelen spesifik hata mesajını logla
      console.error(error.response.body)
    }
  }
}