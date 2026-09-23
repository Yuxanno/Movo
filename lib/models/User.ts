import { Schema, model, models } from "mongoose"

export interface IUser {
  _id?: string
  login: string
  password: string
  name: string
  currency: string
  // ── Настройки безопасности и интерфейса ──────────────────────────────
  pinHash?: string        // bcrypt-хеш PIN-кода (null = PIN не установлен)
  biometricsEnabled?: boolean
  lang?: string           // 'ru' | 'en' | 'uz'
  createdAt?: Date
}

const UserSchema = new Schema<IUser>(
  {
    login:              { type: String, required: true, unique: true },
    password:           { type: String, required: true },
    name:               { type: String, default: "" },
    currency:           { type: String, default: "UZS" },
    pinHash:            { type: String, default: null },
    biometricsEnabled:  { type: Boolean, default: false },
    lang:               { type: String, default: "ru" },
  },
  { timestamps: true }
)

export const User = models.User || model<IUser>("User", UserSchema)
