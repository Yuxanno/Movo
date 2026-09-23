/**
 * Zod-схемы для валидации входящих данных API.
 *
 * Zod уже есть в package.json как прямая зависимость, новых пакетов не нужно.
 * Все схемы экспортируются отдельно, чтобы роуты импортировали только нужное.
 */
import { z } from "zod"

// ── Транзакции ────────────────────────────────────────────────────────────────

export const createTransactionSchema = z.object({
  /** Сумма: строго число, строго больше нуля. Строки ("100") отклоняются. */
  amount: z
    .number({ required_error: "amount обязателен", invalid_type_error: "amount должен быть числом" })
    .positive({ message: "amount должен быть больше нуля" }),

  /** Тип: только два допустимых значения. */
  type: z.enum(["income", "expense"], {
    required_error: "type обязателен",
    message: "type должен быть 'income' или 'expense'",
  }),

  /** Идентификатор счёта: непустая строка (MongoDB ObjectId или любой string-id). */
  accountId: z
    .string({ required_error: "accountId обязателен" })
    .min(1, "accountId не может быть пустым"),

  /** Категория: непустая строка — принимаем любое значение (user-defined categories). */
  category: z
    .string({ required_error: "category обязательна" })
    .min(1, "category не может быть пустой"),

  // Необязательные поля — приходят как есть, не бросают ошибку если отсутствуют

  /** Валюта счёта. */
  currency: z.enum(["UZS", "USD", "RUB"]).optional(),

  /** Произвольное описание операции. */
  description: z.string().max(500, "description не более 500 символов").optional(),

  /** Дата операции. Принимаем ISO-строку или Date-объект. */
  date: z.coerce.date().optional(),
})

/** TypeScript-тип из схемы — используется в роуте для типизации body. */
export type CreateTransactionInput = z.infer<typeof createTransactionSchema>

// ── Аутентификация ────────────────────────────────────────────────────────────

export const loginSchema = z.object({
  login: z
    .string({ required_error: "login обязателен" })
    .min(1, "login не может быть пустым"),
  password: z
    .string({ required_error: "password обязателен" })
    .min(1, "password не может быть пустым"),
})

export const registerSchema = z.object({
  login: z
    .string({ required_error: "login обязателен" })
    .min(3, "login минимум 3 символа")
    .max(32, "login не более 32 символов")
    .regex(/^[a-zA-Z0-9_]+$/, "login может содержать только латинские буквы, цифры и _"),
  password: z
    .string({ required_error: "password обязателен" })
    .min(6, "password минимум 6 символов"),
  name: z
    .string({ required_error: "name обязателен" })
    .min(1, "name не может быть пустым")
    .max(64, "name не более 64 символов"),
  currency: z.enum(["UZS", "USD", "RUB"]).optional().default("UZS"),
})

// ── Счета ─────────────────────────────────────────────────────────────────────

export const createAccountSchema = z.object({
  name: z
    .string({ required_error: "name обязателен" })
    .min(1, "name не может быть пустым")
    .max(64, "name не более 64 символов"),
  icon: z.string().default("home"),
  color: z.string().default("#22c55e"),
  balance: z.number().default(0),
  currency: z.enum(["UZS", "USD", "RUB"]).default("UZS"),
  isShared: z.boolean().default(false),
  sharedWith: z.array(z.string()).optional(),
})

export const updateAccountSchema = createAccountSchema.partial()

export type CreateAccountInput = z.infer<typeof createAccountSchema>
export type UpdateAccountInput = z.infer<typeof updateAccountSchema>

// ── Категории ─────────────────────────────────────────────────────────────────

export const createCategorySchema = z.object({
  name: z
    .string({ required_error: "name обязателен" })
    .min(1, "name не может быть пустым")
    .max(64, "name не более 64 символов"),
  icon: z.string().default("tag"),
  color: z.string().default("#22c55e"),
  type: z.enum(["income", "expense", "both"]).default("expense"),
})

export const updateCategorySchema = createCategorySchema.partial()

export type CreateCategoryInput = z.infer<typeof createCategorySchema>
export type UpdateCategoryInput = z.infer<typeof updateCategorySchema>

// ── Утилита ───────────────────────────────────────────────────────────────────

/**
 * Форматирует ошибки Zod в плоский объект { field: "сообщение" }.
 * Удобнее для клиента, чем сырой ZodError.
 *
 * @example
 * // { amount: "amount должен быть больше нуля", type: "type обязателен" }
 */
export function formatZodErrors(error: z.ZodError): Record<string, string> {
  return Object.fromEntries(
    error.errors.map((e) => [e.path.join(".") || "body", e.message])
  )
}

// ── Категории по умолчанию ────────────────────────────────────────────────────
// Единственный источник правды — раньше этот массив дублировался
// в login/route.ts и register/route.ts (см. анализ проекта).

export const DEFAULT_CATEGORIES = [
  { name: "Продукты",          icon: "food",          color: "#22c55e", type: "expense" },
  { name: "Транспорт",         icon: "transport",     color: "#3b82f6", type: "expense" },
  { name: "Кафе и рестораны",  icon: "cafe",          color: "#f59e0b", type: "expense" },
  { name: "Развлечения",       icon: "entertainment", color: "#8b5cf6", type: "expense" },
  { name: "Здоровье",          icon: "health",        color: "#ef4444", type: "expense" },
  { name: "Одежда",            icon: "clothes",       color: "#ec4899", type: "expense" },
  { name: "Коммунальные",      icon: "utilities",     color: "#f97316", type: "expense" },
  { name: "Другое",            icon: "other",         color: "#9ca3af", type: "expense" },
  { name: "Зарплата",          icon: "salary",        color: "#22c55e", type: "income"  },
  { name: "Подработка",        icon: "work",          color: "#14b8a6", type: "income"  },
] as const
