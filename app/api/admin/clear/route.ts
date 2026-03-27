import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Account } from "@/lib/models/Account"
import { Transaction } from "@/lib/models/Transaction"
import { Category } from "@/lib/models/Category"
import { User } from "@/lib/models/User"

export async function POST() {
  try {
    await connectDB()
    await Promise.all([
      Account.deleteMany({}),
      Transaction.deleteMany({}),
      Category.deleteMany({}),
      User.deleteMany({}),
    ])
    return NextResponse.json({ ok: true, message: "База данных очищена" })
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 })
  }
}
