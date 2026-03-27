import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Transaction } from "@/lib/models/Transaction"
import { Account } from "@/lib/models/Account"

export async function GET(req: Request) {
  try {
    await connectDB()
    const userId = req.headers.get("x-user-id")
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    const { searchParams } = new URL(req.url)
    const accountId = searchParams.get("accountId")
    const filter: Record<string, string> = { userId }
    if (accountId) filter.accountId = accountId
    const transactions = await Transaction.find(filter).sort({ date: -1 }).limit(50)
    return NextResponse.json(transactions)
  } catch {
    return NextResponse.json({ error: "Failed to fetch" }, { status: 500 })
  }
}

export async function POST(req: Request) {
  try {
    await connectDB()
    const userId = req.headers.get("x-user-id")
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    const body = await req.json()
    const tx = await Transaction.create({ ...body, userId })
    const delta = body.type === "income" ? body.amount : -body.amount
    await Account.findByIdAndUpdate(body.accountId, { $inc: { balance: delta } })
    return NextResponse.json(tx, { status: 201 })
  } catch {
    return NextResponse.json({ error: "Failed to create" }, { status: 500 })
  }
}
