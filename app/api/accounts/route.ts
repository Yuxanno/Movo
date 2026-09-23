import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Account } from "@/lib/models/Account"
import { getUserIdFromRequest } from "@/lib/auth"
import { createAccountSchema, formatZodErrors } from "@/lib/validators"

export async function GET(req: Request) {
  try {
    await connectDB()
    const userId = getUserIdFromRequest(req)
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
    const userId = getUserIdFromRequest(req)
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    const rawBody = await req.json()
    const parsed = createAccountSchema.safeParse(rawBody)
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Неверные данные", fields: formatZodErrors(parsed.error) },
        { status: 400 }
      )
    }
    const account = await Account.create({ ...parsed.data, userId })
    return NextResponse.json(account, { status: 201 })
  } catch {
    return NextResponse.json({ error: "Failed to create account" }, { status: 500 })
  }
}
