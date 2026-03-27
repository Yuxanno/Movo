import mongoose, { Schema, model, models } from "mongoose"

export interface ITransaction {
  _id?: string
  userId: string
  accountId: string
  type: "income" | "expense"
  amount: number
  currency: "UZS" | "USD" | "RUB"
  category: string
  description: string
  date: Date
  createdAt?: Date
}

const TransactionSchema = new Schema<ITransaction>(
  {
    userId: { type: String, required: true, index: true },
    accountId: { type: String, required: true },
    type: { type: String, enum: ["income", "expense"], required: true },
    amount: { type: Number, required: true },
    currency: { type: String, enum: ["UZS", "USD", "RUB"], default: "UZS" },
    category: { type: String, default: "other" },
    description: { type: String, default: "" },
    date: { type: Date, default: Date.now },
  },
  { timestamps: true }
)

export const Transaction = models.Transaction || model<ITransaction>("Transaction", TransactionSchema)
