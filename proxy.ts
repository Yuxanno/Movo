import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { checkRateLimit } from "@/lib/rate-limiter";

/**
 * Next.js Proxy — выполняется на каждый запрос до того, как он достигнет роута.
 *
 * Реализует:
 * 1. CORS для API-эндпоинтов (Flutter-приложение обращается с другого origin)
 * 2. Rate limiting для эндпоинтов аутентификации
 */

// Конфигурация лимитов для каждого защищаемого пути
const AUTH_RATE_LIMITS: Record<string, { limit: number; windowMs: number }> = {
  // Логин: 10 попыток в 15 минут с одного IP
  "/api/auth/login": { limit: 10, windowMs: 15 * 60 * 1000 },

  // Регистрация: 5 аккаунтов в 15 минут с одного IP
  "/api/auth/register": { limit: 5, windowMs: 15 * 60 * 1000 },
};

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // ── CORS для API-роутов ──────────────────────────────────────────────
  if (pathname.startsWith("/api")) {
    const origin = request.headers.get("origin") || "*";

    // Handle Preflight (OPTIONS) requests first
    if (request.method === "OPTIONS") {
      return new NextResponse(null, {
        status: 204,
        headers: {
          "Access-Control-Allow-Origin": origin,
          "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
          "Access-Control-Allow-Headers":
            "Content-Type, Authorization, X-Requested-With, x-user-id",
          "Access-Control-Max-Age": "86400",
        },
      });
    }

    // ── Rate Limiting для аутентификации ──────────────────────────────
    const limitConfig = AUTH_RATE_LIMITS[pathname];
    if (limitConfig) {
      const ip =
        request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ??
        request.headers.get("x-real-ip") ??
        "unknown";

      const key = `${ip}:${pathname}`;
      const result = checkRateLimit(key, limitConfig);

      const rateLimitHeaders = new Headers({
        "X-RateLimit-Limit": String(limitConfig.limit),
        "X-RateLimit-Remaining": String(result.remaining),
        "X-RateLimit-Reset": String(Math.ceil(result.resetAt / 1000)),
      });

      if (result.limited) {
        const retryAfterSec = Math.ceil((result.resetAt - Date.now()) / 1000);
        rateLimitHeaders.set("Retry-After", String(retryAfterSec));
        // Добавляем CORS-заголовки и к ответу 429
        rateLimitHeaders.set("Access-Control-Allow-Origin", origin);

        return NextResponse.json(
          {
            error: "Слишком много запросов. Попробуйте позже.",
            retryAfter: retryAfterSec,
          },
          {
            status: 429,
            headers: rateLimitHeaders,
          }
        );
      }

      // Запрос разрешён — пропускаем с CORS + rate limit заголовками
      const response = NextResponse.next();
      response.headers.set("Access-Control-Allow-Origin", origin);
      response.headers.set(
        "Access-Control-Allow-Methods",
        "GET, POST, PUT, DELETE, OPTIONS"
      );
      response.headers.set(
        "Access-Control-Allow-Headers",
        "Content-Type, Authorization, X-Requested-With, x-user-id"
      );
      response.headers.set("Access-Control-Max-Age", "86400");
      rateLimitHeaders.forEach((value, name) =>
        response.headers.set(name, value)
      );
      return response;
    }

    // Обычный API-запрос (не auth) — только CORS
    const response = NextResponse.next();
    response.headers.set("Access-Control-Allow-Origin", origin);
    response.headers.set(
      "Access-Control-Allow-Methods",
      "GET, POST, PUT, DELETE, OPTIONS"
    );
    response.headers.set(
      "Access-Control-Allow-Headers",
      "Content-Type, Authorization, X-Requested-With, x-user-id"
    );
    response.headers.set("Access-Control-Max-Age", "86400");
    return response;
  }

  return NextResponse.next();
}

export default proxy;

export const config = {
  matcher: ["/api/:path*"],
};
