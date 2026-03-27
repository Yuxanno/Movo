import { Schema, model, models } from "mongoose"

export interface IUser {
  _id?: string
  login: string
  password: string
  name: string
  currency: string
  createdAt?: Date
}

const UserSchema = new Schema<IUser>(
  {
    login: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    name: { type: String, default: "" },
    currency: { type: String, default: "UZS" },
  },
  { timestamps: true }
)

export const User = models.User || model<IUser>("User", UserSchema)
