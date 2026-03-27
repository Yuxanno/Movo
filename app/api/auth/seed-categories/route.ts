import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Category } from "@/lib/models/Category"

const DEFAULT_CATEGORIES = [
  { name: "Продукты",         icon: "food",          color: "#22c55e", type: "expense" },
  { name: "Транспорт",        icon: "transport",     color: "#3b82f6", type: "expense" },
  { name: "Кафе и рестораны", icon: "cafe",          color: "#f59e0b", type: "expense" },
  { name: "Развлечения",      icon: "entertainment", color: "#8b5cf6", type: "expense" },
  { name: "Здоровье",         icon: "health",        color: "#ef4444", type: "expense" },
  { name: "Одежда",           icon: "clothes",       color: "#ec4899", type: "expense" },
  { name: "Коммунальные",     icon: "utilities",     color: "#f97316", type: "expense" },
  { name: "Другое",           icon: "other",         color: "#9ca3af", type: "expense" },
  { name: "Зарплата",         icon: "salary",        color: "#22c55e", type: "income"  },
  { name: "Подработка",       icon: "work",          color: "#14b8a6", type: "income"  },
]

export async function POST(req: Request) {
  try {
    await connectDB()
    const userId = req.headers.get("x-user-id")
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    const count = await Category.countDocuments({ userId })
    if (count > 0) return NextResponse.json({ ok: true, seeded: false })
    await Category.insertMany(DEFAULT_CATEGORIES.map(c => ({ ...c, userId })))
    return NextResponse.json({ ok: true, seeded: true })
  } catch {
    return NextResponse.json({ error: "Failed" }, { status: 500 })
  }
}
