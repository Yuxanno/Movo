import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Transaction } from "@/lib/models/Transaction"
import { Account } from "@/lib/models/Account"
import { getUserIdFromRequest } from "@/lib/auth"

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const mongooseConn = await connectDB()
    const { id } = await params
    const userId = getUserIdFromRequest(req)
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })

    const session = await mongooseConn.startSession()

    try {
      await session.withTransaction(async () => {
        const tx = await Transaction.findOneAndDelete({ _id: id, userId }).session(session)
        if (!tx) {
          console.warn(`Transaction not found for ID: ${id}, User: ${userId}`)
          throw new Error("Transaction not found")
        }

        const delta = tx.type === "income" ? -tx.amount : tx.amount
        const updatedAccount = await Account.findOneAndUpdate(
          { _id: tx.accountId, userId },
          { $inc: { balance: delta } },
          { new: true, session }
        )

        if (!updatedAccount) {
          console.error(`Failed to update account ${tx.accountId} after deleting transaction ${id}`)
          throw new Error("Account not found")
        }
      })

      return NextResponse.json({ ok: true, message: "Deleted successfully" })
    } finally {
      session.endSession()
    }
  } catch (error: unknown) {
    if (error instanceof Error && (error.message === "Transaction not found" || error.message === "Account not found")) {
      return NextResponse.json({ error: "Not found" }, { status: 404 })
    }
    const msg = error instanceof Error ? error.message : String(error)
    console.error("DELETE TRANSACTION ERROR:", msg)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
