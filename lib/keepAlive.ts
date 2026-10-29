/**
 * Keep-alive для Render Free tier.
 * Каждые 45 сек пингует собственный /api/health чтобы инстанс не засыпал.
 * Запускается один раз при старте сервера через instrumentation.ts
 */

const INTERVAL_MS = 45_000
let started = false

export function startKeepAlive() {
  // Не запускать на локалке и не дублировать
  if (process.env.NODE_ENV !== "production") return
  if (started) return
  started = true

  const baseUrl = process.env.RENDER_EXTERNAL_URL ?? process.env.NEXT_PUBLIC_API_URL

  if (!baseUrl) {
    console.warn("[keep-alive] No base URL found, skipping.")
    return
  }

  const url = `${baseUrl}/api/health`
  console.log(`[keep-alive] Started — pinging ${url} every ${INTERVAL_MS / 1000}s`)

  setInterval(async () => {
    try {
      const res = await fetch(url, { cache: "no-store" })
      const data = await res.json()
      console.log(`[keep-alive] ping ok — db:${data.db} latency:${data.latency_ms}ms`)
    } catch (err) {
      console.warn("[keep-alive] ping failed:", err)
    }
  }, INTERVAL_MS)
}
