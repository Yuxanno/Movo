import { NextResponse } from "next/server"
import bcrypt from "bcryptjs"
import { connectDB } from "@/lib/db"
import { User } from "@/lib/models/User"
import { getUserIdFromRequest } from "@/lib/auth"

// Обработка CORS preflight запроса (OPTIONS)
export async function OPTIONS() {
  return new NextResponse(null, {
    status: 204,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET,POST,PUT,PATCH,DELETE,OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    },
  })
}

/**
 * GET /api/user/settings
 * Возвращает настройки текущего пользователя: pinEnabled, biometricsEnabled, lang.
 * PIN-хеш никогда не передаётся клиенту — только флаг "установлен или нет".
 */
export async function GET(req: Request) {
  try {
    await connectDB()

    const userId = getUserIdFromRequest(req)
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })

    const user = await User.findById(userId).select("pinHash biometricsEnabled lang")
    if (!user) return NextResponse.json({ error: "Not found" }, { status: 404 })

    return NextResponse.json({
      pinEnabled: !!user.pinHash,
      biometricsEnabled: user.biometricsEnabled ?? false,
      lang: user.lang ?? "ru",
    })
  } catch {
    return NextResponse.json({ error: "Ошибка сервера" }, { status: 500 })
  }
}

/**
 * PATCH /api/user/settings
 * Обновляет одно или несколько полей настроек.
 *
 * Тело запроса (все поля опциональны):
 *   { pinCode?: string | null, biometricsEnabled?: boolean, lang?: string }
 *
 * pinCode:
 *   - строка  → сохраняем bcrypt-хеш нового PIN
 *   - null     → удаляем PIN (устанавливаем pinHash = null)
 *   - поле отсутствует → PIN не трогаем
 *
 * Для смены PIN — клиент ОБЯЗАН передать currentPin чтобы мы проверили старый PIN.
 * Для удаления PIN — тоже нужен currentPin.
 * Для biometricsEnabled и lang — currentPin не нужен.
 */
export async function PATCH(req: Request) {
  try {
    await connectDB()

    const userId = getUserIdFromRequest(req)
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })

    const body = await req.json()
    const { pinCode, currentPin, biometricsEnabled, lang } = body

    const user = await User.findById(userId)
    if (!user) return NextResponse.json({ error: "Not found" }, { status: 404 })

    const updates: Record<string, unknown> = {}

    // ── PIN ────────────────────────────────────────────────────────────────────
    if ("pinCode" in body) {
      if (pinCode === null) {
        // Удаление PIN — требуем подтверждение текущего PIN
        if (user.pinHash) {
          if (!currentPin) {
            return NextResponse.json({ error: "Требуется текущий PIN" }, { status: 400 })
          }
          const valid = await bcrypt.compare(String(currentPin), user.pinHash)
          if (!valid) {
            return NextResponse.json({ error: "Неверный PIN" }, { status: 403 })
          }
        }
        updates.pinHash = null
      } else if (typeof pinCode === "string" && pinCode.length >= 4) {
        // Установка нового PIN
        // Если PIN уже был установлен — требуем старый
        if (user.pinHash) {
          if (!currentPin) {
            return NextResponse.json({ error: "Требуется текущий PIN" }, { status: 400 })
          }
          const valid = await bcrypt.compare(String(currentPin), user.pinHash)
          if (!valid) {
            return NextResponse.json({ error: "Неверный PIN" }, { status: 403 })
          }
        }
        updates.pinHash = await bcrypt.hash(pinCode, 10)
      } else {
        return NextResponse.json({ error: "pinCode должен быть строкой (≥4 символов) или null" }, { status: 400 })
      }
    }

    // ── Биометрия ──────────────────────────────────────────────────────────────
    if (typeof biometricsEnabled === "boolean") {
      updates.biometricsEnabled = biometricsEnabled
    }

    // ── Язык ───────────────────────────────────────────────────────────────────
    if (typeof lang === "string" && ["ru", "en", "uz"].includes(lang)) {
      updates.lang = lang
    }

    if (Object.keys(updates).length === 0) {
      return NextResponse.json({ error: "Нет данных для обновления" }, { status: 400 })
    }

    await User.findByIdAndUpdate(userId, updates)

    return NextResponse.json({
      pinEnabled: "pinHash" in updates ? updates.pinHash !== null : !!user.pinHash,
      biometricsEnabled: "biometricsEnabled" in updates
        ? updates.biometricsEnabled
        : (user.biometricsEnabled ?? false),
      lang: "lang" in updates ? updates.lang : (user.lang ?? "ru"),
    })
  } catch {
    return NextResponse.json({ error: "Ошибка сервера" }, { status: 500 })
  }
}
