import { NextResponse } from "next/server"
import bcrypt from "bcryptjs"
import { connectDB } from "@/lib/db"
import { User } from "@/lib/models/User"
import { Category } from "@/lib/models/Category"
import { signToken } from "@/lib/auth"
import { loginSchema, formatZodErrors, DEFAULT_CATEGORIES } from "@/lib/validators"

export async function POST(req: Request) {
  try {
    await connectDB()

    const rawBody = await req.json()

    // ── Валидация входящих данных ──────────────────────────────────────────────
    const parsed = loginSchema.safeParse(rawBody)
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Неверные данные", fields: formatZodErrors(parsed.error) },
        { status: 400 }
      )
    }

    const { login, password } = parsed.data

    // Ищем только по логину — пароль проверяем отдельно через bcrypt.
    // Нельзя искать по { login, password }, т.к. в БД хранится хеш.
    const user = await User.findOne({ login })
    if (!user) {
      // Возвращаем то же сообщение что и при неверном пароле —
      // чтобы не давать подсказку о существовании логина (timing-safe)
      return NextResponse.json({ error: "Неверный логин или пароль" }, { status: 401 })
    }

    // bcrypt.compare безопасно сравнивает сырой пароль с хешем.
    const isPasswordValid = await bcrypt.compare(password, user.password)
    if (!isPasswordValid) {
      return NextResponse.json({ error: "Неверный логин или пароль" }, { status: 401 })
    }

    // Сидируем дефолтные категории если у пользователя их ещё нет.
    // DEFAULT_CATEGORIES теперь импортируется из lib/validators — единый источник правды.
    const count = await Category.countDocuments({ userId: user._id.toString() })
    if (count === 0) {
      await Category.insertMany(
        DEFAULT_CATEGORIES.map((c) => ({ ...c, userId: user._id.toString() }))
      )
    }

    const token = signToken(user._id.toString())

    return NextResponse.json({
      _id: user._id,
      login: user.login,
      name: user.name,
      currency: user.currency,
      pinEnabled: !!user.pinHash,
      biometricsEnabled: user.biometricsEnabled ?? false,
      lang: user.lang ?? "ru",
      token,
    })
  } catch {
    return NextResponse.json({ error: "Ошибка сервера" }, { status: 500 })
  }
}
