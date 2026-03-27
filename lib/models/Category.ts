import mongoose, { Schema, model, models } from "mongoose"

export interface ICategory {
  _id?: string
  userId: string
  name: string
  icon: string
  color: string
  type: "income" | "expense" | "both"
}

const CategorySchema = new Schema<ICategory>(
  {
    userId: { type: String, required: true, index: true },
    name: { type: String, required: true },
    icon: { type: String, default: "tag" },
    color: { type: String, default: "#22c55e" },
    type: { type: String, enum: ["income", "expense", "both"], default: "expense" },
  },
  { timestamps: true }
)

export const Category = models.Category || model<ICategory>("Category", CategorySchema)
