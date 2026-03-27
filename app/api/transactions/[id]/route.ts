import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Transaction } from "@/lib/models/Transaction"
import { Account } from "@/lib/models/Account"

export async function DELETE(req: Request, { params }: { params: { id: string } }) {
  try {
    await connectDB()
    const userId = req.headers.get("x-user-id")
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    const tx = await Transaction.findOne({ _id: params.id, userId })
    if (!tx) return NextResponse.json({ error: "Not found" }, { status: 404 })
    // Reverse the balance effect
    const delta = tx.type === "income" ? -tx.amount : tx.amount
    await Account.findByIdAndUpdate(tx.accountId, { $inc: { balance: delta } })
    await tx.deleteOne()
    return NextResponse.json({ ok: true })
  } catch {
    return NextResponse.json({ error: "Failed to delete" }, { status: 500 })
  }
}
