import { NextResponse } from "next/server"
import bcrypt from "bcryptjs"
import { connectDB } from "@/lib/db"
import { User } from "@/lib/models/User"
import { Category } from "@/lib/models/Category"
import { signToken } from "@/lib/auth"
import { registerSchema, formatZodErrors, DEFAULT_CATEGORIES } from "@/lib/validators"

export async function POST(req: Request) {
  try {
    await connectDB()

    const rawBody = await req.json()

    // ── Валидация входящих данных ──────────────────────────────────────────────
    // registerSchema проверяет: login (3-32 символа, [a-zA-Z0-9_]),
    // password (мин. 6), name (непустое), currency (enum или default "UZS")
    const parsed = registerSchema.safeParse(rawBody)
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Неверные данные", fields: formatZodErrors(parsed.error) },
        { status: 400 }
      )
    }

    const { login, password, name, currency } = parsed.data

    const exists = await User.findOne({ login })
    if (exists) {
      return NextResponse.json({ error: "Логин уже занят" }, { status: 409 })
    }

    // Хешируем пароль перед сохранением.
    // cost factor 10 — стандартный баланс безопасности и скорости (~100ms на сервере).
    const hashedPassword = await bcrypt.hash(password, 10)

    const user = await User.create({ login, password: hashedPassword, name, currency })

    // DEFAULT_CATEGORIES теперь импортируется из lib/validators — единый источник правды.
    await Category.insertMany(
      DEFAULT_CATEGORIES.map((c) => ({ ...c, userId: user._id.toString() }))
    )

    const token = signToken(user._id.toString())

    return NextResponse.json(
      {
        _id: user._id,
        login: user.login,
        name: user.name,
        currency: user.currency,
        pinEnabled: false,
        biometricsEnabled: false,
        lang: "ru",
        token,
      },
      { status: 201 }
    )
  } catch {
    return NextResponse.json({ error: "Ошибка сервера" }, { status: 500 })
  }
}
