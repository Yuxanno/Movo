import mongoose, { Schema, model, models } from "mongoose"

export interface IAccount {
  _id?: string
  userId: string
  name: string
  icon: string
  color: string
  balance: number
  currency: "UZS" | "USD" | "RUB"
  isShared: boolean
  sharedWith?: string[]
  createdAt?: Date
}

const AccountSchema = new Schema<IAccount>(
  {
    userId: { type: String, required: true, index: true },
    name: { type: String, required: true },
    icon: { type: String, default: "home" },
    color: { type: String, default: "#22c55e" },
    balance: { type: Number, default: 0 },
    currency: { type: String, enum: ["UZS", "USD", "RUB"], default: "UZS" },
    isShared: { type: Boolean, default: false },
    sharedWith: [{ type: String }],
  },
  { timestamps: true }
)

export const Account = models.Account || model<IAccount>("Account", AccountSchema)
