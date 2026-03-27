import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Account } from "@/lib/models/Account"

export async function GET(req: Request) {
  try {
    await connectDB()
    const userId = req.headers.get("x-user-id")
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    const accounts = await Account.find({ userId }).sort({ createdAt: -1 })
    return NextResponse.json(accounts)
  } catch {
    return NextResponse.json({ error: "Failed to fetch accounts" }, { status: 500 })
  }
}

export async function POST(req: Request) {
  try {
    await connectDB()
    const userId = req.headers.get("x-user-id")
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    const body = await req.json()
    const account = await Account.create({ ...body, userId })
    return NextResponse.json(account, { status: 201 })
  } catch {
    return NextResponse.json({ error: "Failed to create account" }, { status: 500 })
  }
}
