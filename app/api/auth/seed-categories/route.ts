import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Category } from "@/lib/models/Category"
import { getUserIdFromRequest } from "@/lib/auth"
import { DEFAULT_CATEGORIES } from "@/lib/validators"

// Локальный DEFAULT_CATEGORIES удалён — используем единый источник из lib/validators.

export async function POST(req: Request) {
  try {
    await connectDB()

    // Мигрировано с x-user-id на стандартный JWT Bearer — согласованно с остальными роутами
    const userId = getUserIdFromRequest(req)
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })

    const count = await Category.countDocuments({ userId })
    if (count > 0) return NextResponse.json({ ok: true, seeded: false })

    await Category.insertMany(DEFAULT_CATEGORIES.map((c) => ({ ...c, userId })))
    return NextResponse.json({ ok: true, seeded: true })
  } catch {
    return NextResponse.json({ error: "Failed" }, { status: 500 })
  }
}
