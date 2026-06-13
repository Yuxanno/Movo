import { NextResponse } from "next/server"
import bcrypt from "bcryptjs"
import { connectDB } from "@/lib/db"
import { User } from "@/lib/models/User"
import { Category } from "@/lib/models/Category"
import { signToken } from "@/lib/auth"

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
    console.log("Login request received")
    await connectDB()
    const { login, password } = await req.json()
    console.log("Searching for user:", login)

    // Ищем только по логину — пароль проверяем отдельно через bcrypt.
    // Нельзя искать по { login, password }, т.к. в БД хранится хеш, а не сырой пароль.
    const user = await User.findOne({ login })
    if (!user) {
      console.log("User not found")
      // Возвращаем то же сообщение что и при неверном пароле —
      // чтобы не давать подсказку о существовании логина (timing-safe)
      return NextResponse.json({ error: "Неверный логин или пароль" }, { status: 401 })
    }

    // bcrypt.compare безопасно сравнивает сырой пароль с хешем.
    // Возвращает false если хеш не совпадает или пользователь создан до хеширования.
    const isPasswordValid = await bcrypt.compare(password, user.password)
    if (!isPasswordValid) {
      console.log("Wrong password for user:", login)
      return NextResponse.json({ error: "Неверный логин или пароль" }, { status: 401 })
    }

    console.log("User logged in:", user.login)

    // Сидируем дефолтные категории если у пользователя их ещё нет
    const count = await Category.countDocuments({ userId: user._id.toString() })
    if (count === 0) {
      await Category.insertMany(DEFAULT_CATEGORIES.map(c => ({ ...c, userId: user._id.toString() })))
    }

    const token = signToken(user._id.toString())

    return NextResponse.json({
      _id: user._id,
      login: user.login,
      name: user.name,
      currency: user.currency,
      token,
    })
  } catch {
    return NextResponse.json({ error: "Ошибка сервера" }, { status: 500 })
  }
}
