/**
 * In-memory rate limiter для Next.js Middleware (Edge Runtime совместимый).
 *
 * Почему не express-rate-limit:
 *   Next.js App Router не использует Express — middleware работает в Edge Runtime,
 *   где нет доступа к Node.js модулям. express-rate-limit здесь просто не запустится.
 *
 * Ограничения in-memory подхода:
 *   - Счётчики сбрасываются при перезапуске сервера (приемлемо для нашего случая)
 *   - Не работает в multi-instance деплое (несколько pod'ов Vercel/K8s)
 *   - Для production multi-instance нужен Redis + @upstash/ratelimit
 *
 * Для single-instance VPS (наш случай с MongoDB на Atlas) — достаточно.
 */

interface RateLimitEntry {
  count: number
  resetAt: number // Unix timestamp (ms)
}

// Глобальная карта: IP → { count, resetAt }
// Хранится в памяти процесса весь срок его жизни
const store = new Map<string, RateLimitEntry>()

// Периодическая очистка истёкших записей, чтобы Map не рос бесконечно
// Запускаем раз в минуту только в Node.js среде (не Edge)
if (typeof setInterval !== "undefined") {
  setInterval(() => {
    const now = Date.now()
    for (const [key, entry] of store.entries()) {
      if (entry.resetAt < now) store.delete(key)
    }
  }, 60_000)
}

export interface RateLimitOptions {
  /** Максимальное число запросов за окно */
  limit: number
  /** Длина окна в миллисекундах */
  windowMs: number
}

export interface RateLimitResult {
  /** true — лимит превышен, запрос нужно отклонить */
  limited: boolean
  /** Сколько запросов уже сделано */
  current: number
  /** Сколько запросов осталось */
  remaining: number
  /** Когда (Unix ms) окно сбросится */
  resetAt: number
}

/**
 * Проверяет и инкрементирует счётчик для переданного ключа (обычно IP-адрес).
 *
 * @param key     - Уникальный ключ (IP + путь, чтобы лимиты не пересекались)
 * @param options - { limit, windowMs }
 */
export function checkRateLimit(key: string, options: RateLimitOptions): RateLimitResult {
  const now = Date.now()
  const entry = store.get(key)

  if (!entry || entry.resetAt < now) {
    // Первый запрос или окно истекло — создаём новый счётчик
    const newEntry: RateLimitEntry = { count: 1, resetAt: now + options.windowMs }
    store.set(key, newEntry)
    return { limited: false, current: 1, remaining: options.limit - 1, resetAt: newEntry.resetAt }
  }

  // Инкрементируем существующий счётчик
  entry.count += 1
  store.set(key, entry)

  const limited = entry.count > options.limit
  return {
    limited,
    current: entry.count,
    remaining: Math.max(0, options.limit - entry.count),
    resetAt: entry.resetAt,
  }
}
