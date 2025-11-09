import jwt from "jsonwebtoken";
export function signToken(user) {
  const payload = { sub: user._id.toString(), role: user.role || "user", aud: "mobile" };
  return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES || "7d" });
}
export function verifyToken(token) { return jwt.verify(token, process.env.JWT_SECRET); }
