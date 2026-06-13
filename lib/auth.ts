import jwt from "jsonwebtoken"

const JWT_SECRET = process.env.JWT_SECRET!

if (!JWT_SECRET) {
  throw new Error("JWT_SECRET is not defined in environment variables")
}

interface JwtPayload {
  userId: string
  iat: number
  exp?: number // необязателен — при expiresIn: '10y' присутствует, без него отсутствует
}

/**
 * Извлекает и верифицирует JWT из заголовка Authorization запроса.
 *
 * @returns userId (строка) при успехе
 * @returns null если токен отсутствует, невалиден или истёк
 *
 * Использование в роуте:
 *   const userId = getUserIdFromRequest(req)
 *   if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
 */
export function getUserIdFromRequest(req: Request): string | null {
  const authHeader = req.headers.get("Authorization")

  // Заголовок должен быть вида: "Bearer <token>"
  if (!authHeader || !authHeader.startsWith("Bearer ")) return null

  const token = authHeader.slice(7) // убираем "Bearer "
  if (!token) return null

  try {
    const payload = jwt.verify(token, JWT_SECRET) as JwtPayload
    return payload.userId
  } catch {
    // Покрывает: TokenExpiredError, JsonWebTokenError, NotBeforeError
    return null
  }
}

/**
 * Генерирует JWT-токен с вшитым userId.
 * Вызывается только в роутах login и register.
 *
 * @param userId — MongoDB ObjectId пользователя в виде строки
 * @returns подписанный JWT-токен, действительный 10 лет
 *
 * Почему 10 лет, а не бессрочный:
 *   - Пользователь никогда не замечает разлогина на практике
 *   - Сохраняется возможность инвалидировать старые токены через смену JWT_SECRET
 *   - Бессрочный токен нельзя отозвать никаким способом без базы данных сессий
 */
export function signToken(userId: string): string {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: "10y" })
}
