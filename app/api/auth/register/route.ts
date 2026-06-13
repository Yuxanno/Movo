import { NextResponse } from "next/server"
import bcrypt from "bcryptjs"
import { connectDB } from "@/lib/db"
import { User } from "@/lib/models/User"
import { Category } from "@/lib/models/Category"
import { signToken } from "@/lib/auth"

const DEFAULT_CATEGORIES = [
  { name: "Продукты",      icon: "food",          color: "#22c55e", type: "expense" },
  { name: "Транспорт",     icon: "transport",     color: "#3b82f6", type: "expense" },
  { name: "Кафе и рестораны", icon: "cafe",       color: "#f59e0b", type: "expense" },
  { name: "Развлечения",   icon: "entertainment", color: "#8b5cf6", type: "expense" },
  { name: "Здоровье",      icon: "health",        color: "#ef4444", type: "expense" },
  { name: "Одежда",        icon: "clothes",       color: "#ec4899", type: "expense" },
  { name: "Коммунальные",  icon: "utilities",     color: "#f97316", type: "expense" },
  { name: "Другое",        icon: "other",         color: "#9ca3af", type: "expense" },
  { name: "Зарплата",      icon: "salary",        color: "#22c55e", type: "income"  },
  { name: "Подработка",    icon: "work",          color: "#14b8a6", type: "income"  },
]

export async function POST(req: Request) {
  try {
    await connectDB()
    const { login, password, name, currency } = await req.json()
    if (!login || !password) return NextResponse.json({ error: "Заполните все поля" }, { status: 400 })
    const exists = await User.findOne({ login })
    if (exists) return NextResponse.json({ error: "Логин уже занят" }, { status: 409 })

    // Хешируем пароль перед сохранением.
    // cost factor 10 — стандартный баланс безопасности и скорости (~100ms на сервере).
    // В MongoDB будет храниться хеш вида: $2a$10$...
    const hashedPassword = await bcrypt.hash(password, 10)

    const user = await User.create({ login, password: hashedPassword, name, currency })
    await Category.insertMany(DEFAULT_CATEGORIES.map(c => ({ ...c, userId: user._id.toString() })))

    const token = signToken(user._id.toString())

    return NextResponse.json({
      _id: user._id,
      login: user.login,
      name: user.name,
      currency: user.currency,
      token,
    }, { status: 201 })
  } catch {
    return NextResponse.json({ error: "Ошибка сервера" }, { status: 500 })
  }
}
