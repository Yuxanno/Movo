import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Transaction } from "@/lib/models/Transaction"
import { Account } from "@/lib/models/Account"

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await connectDB()
    const { id } = await params
    const userId = req.headers.get("x-user-id")
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })

    // Use findOneAndDelete to reduce DB roundtrips (1 operation instead of find + delete)
    const tx = await Transaction.findOneAndDelete({ _id: id, userId })
    if (!tx) {
      console.warn(`Transaction not found for ID: ${id}, User: ${userId}`);
      return NextResponse.json({ error: "Not found" }, { status: 404 })
    }

    // Reverse the balance effect on the linked account
    const delta = tx.type === "income" ? -tx.amount : tx.amount
    const updatedAccount = await Account.findOneAndUpdate(
      { _id: tx.accountId, userId },
      { $inc: { balance: delta } },
      { new: true }
    )

    if (!updatedAccount) {
      console.error(`Failed to update account ${tx.accountId} after deleting transaction ${id}`);
    }

    return NextResponse.json({ ok: true, message: "Deleted successfully" })
  } catch (error: any) {
    console.error("DELETE TRANSACTION ERROR for ID:", id, error.message || error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
