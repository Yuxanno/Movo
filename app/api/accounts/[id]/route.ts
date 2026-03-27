import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Account } from "@/lib/models/Account"

export async function DELETE(_: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await connectDB()
    const { id } = await params
    await Account.findByIdAndDelete(id)
    return NextResponse.json({ success: true })
  } catch {
    return NextResponse.json({ error: "Failed to delete" }, { status: 500 })
  }
}

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await connectDB()
    const { id } = await params
    const body = await req.json()
    const account = await Account.findByIdAndUpdate(id, body, { new: true })
    return NextResponse.json(account)
  } catch {
    return NextResponse.json({ error: "Failed to update" }, { status: 500 })
  }
}
