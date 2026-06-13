import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Account } from "@/lib/models/Account"
import { getUserIdFromRequest } from "@/lib/auth"

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await connectDB()
    const userId = getUserIdFromRequest(req)
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    const { id } = await params
    // Удаляем только если счёт принадлежит этому пользователю
    await Account.findOneAndDelete({ _id: id, userId })
    return NextResponse.json({ success: true })
  } catch {
    return NextResponse.json({ error: "Failed to delete" }, { status: 500 })
  }
}

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await connectDB()
    const userId = getUserIdFromRequest(req)
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    const { id } = await params
    const body = await req.json()
    // Обновляем только если счёт принадлежит этому пользователю
    const account = await Account.findOneAndUpdate({ _id: id, userId }, body, { new: true })
    if (!account) return NextResponse.json({ error: "Not found" }, { status: 404 })
    return NextResponse.json(account)
  } catch {
    return NextResponse.json({ error: "Failed to update" }, { status: 500 })
  }
}
