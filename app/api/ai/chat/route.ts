import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Transaction } from "@/lib/models/Transaction"
import { Account } from "@/lib/models/Account"
import { Category } from "@/lib/models/Category"
import { getUserIdFromRequest } from "@/lib/auth"

/**
 * POST /api/ai/chat
 *
 * Принимает сообщение пользователя, загружает все его финансовые данные,
 * формирует контекст и отправляет в Groq API (llama-3.3-70b-versatile).
 *
 * ИИ имеет полный доступ к данным пользователя и даёт персонализированные,
 * короткие (2-4 предложения) и практичные советы.
 *
 * Тело: { message: string, lang?: string }
 * Ответ: { reply: string }
 */
export async function POST(req: Request) {
  try {
    await connectDB()

    const userId = getUserIdFromRequest(req)
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })

    const { message, lang } = await req.json()
    if (!message || typeof message !== "string") {
      return NextResponse.json({ error: "No message provided" }, { status: 400 })
    }

    const groqKey = process.env.GROQ_API
    if (!groqKey) {
      return NextResponse.json({ error: "GROQ_API key not configured" }, { status: 500 })
    }

    // ── Загружаем ВСЕ данные пользователя ────────────────────────────────
    const [accounts, transactions, categories] = await Promise.all([
      Account.find({ userId }).lean(),
      Transaction.find({ userId }).sort({ date: -1 }).limit(100).lean(),
      Category.find({ userId }).lean(),
    ])

    // ── Формируем финансовый контекст ────────────────────────────────────
    const context = buildFinancialContext(accounts, transactions, categories)

    // Язык ответа — по выбору клиента
    const langInstruction = lang === "en"
      ? "Respond in English."
      : lang === "uz"
      ? "O'zbek tilida javob bering."
      : "Отвечай на русском языке."

    const systemPrompt = `Ты — персональный финансовый советник в приложении Movo.
Твоя задача — давать короткие, конкретные и практичные советы на основе реальных финансовых данных пользователя.

ПРАВИЛА:
1. Отвечай КОРОТКО — максимум 2-4 предложения. Никаких лекций.
2. Будь КОНКРЕТНЫМ — используй реальные цифры из данных пользователя (суммы, проценты, названия категорий).
3. НЕ давай банальные советы вроде «не трать на еду», «экономь деньги», «веди бюджет». Все это и так знают.
4. Предлагай ДЕЙСТВИЯ: «переведи X на сбережения», «категория Y занимает Z% — вот альтернатива», «доходы выросли на N — рассмотри инвестиции».
5. Если пользователь спрашивает — отвечай на его вопрос, используя его финансовые данные.
6. Если данных мало (меньше 3 транзакций) — скажи что нужно больше данных и дай общий короткий совет.
7. ${langInstruction}

Данные пользователя:
${context}`

    // ── Запрос к Groq API ────────────────────────────────────────────────
    // Модель: openai/gpt-oss-120b — reasoning-модель от OpenAI, хостится на Groq.
    const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${groqKey}`,
      },
      body: JSON.stringify({
        model: "openai/gpt-oss-120b",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: message },
        ],
        max_completion_tokens: 2048,
        temperature: 1,
        top_p: 1,
        reasoning_effort: "medium",
      }),
    })

    if (!res.ok) {
      const errText = await res.text()
      console.error("Groq API error:", errText)
      return NextResponse.json({ error: "AI service error" }, { status: 502 })
    }

    const data = await res.json()
    const reply = data.choices?.[0]?.message?.content ?? "Извините, не смог сформировать ответ."

    return NextResponse.json({ reply })
  } catch (error) {
    console.error("AI chat error:", error)
    return NextResponse.json({ error: "Ошибка сервера" }, { status: 500 })
  }
}

// ── Формирует текстовую сводку финансовых данных пользователя ────────────────

function buildFinancialContext(
  accounts: any[],
  transactions: any[],
  categories: any[]
): string {
  const lines: string[] = []

  // Счета
  if (accounts.length > 0) {
    lines.push("=== СЧЕТА ===")
    let totalBalance = 0
    for (const a of accounts) {
      totalBalance += a.balance
      lines.push(`- ${a.name}: ${a.balance} ${a.currency}${a.isShared ? " (совместный)" : ""}`)
    }
    lines.push(`Общий баланс: ${totalBalance}`)
    lines.push("")
  }

  // Транзакции — сводка
  if (transactions.length > 0) {
    const now = new Date()
    const thisMonth = transactions.filter(t => {
      const d = new Date(t.date)
      return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear()
    })
    const lastMonth = transactions.filter(t => {
      const d = new Date(t.date)
      const lm = new Date(now.getFullYear(), now.getMonth() - 1, 1)
      return d.getMonth() === lm.getMonth() && d.getFullYear() === lm.getFullYear()
    })

    const monthIncome = thisMonth.filter(t => t.type === "income").reduce((s, t) => s + t.amount, 0)
    const monthExpense = thisMonth.filter(t => t.type === "expense").reduce((s, t) => s + t.amount, 0)
    const prevMonthIncome = lastMonth.filter(t => t.type === "income").reduce((s, t) => s + t.amount, 0)
    const prevMonthExpense = lastMonth.filter(t => t.type === "expense").reduce((s, t) => s + t.amount, 0)

    lines.push("=== ТЕКУЩИЙ МЕСЯЦ ===")
    lines.push(`Доходы: ${monthIncome}`)
    lines.push(`Расходы: ${monthExpense}`)
    lines.push(`Баланс: ${monthIncome - monthExpense}`)

    if (prevMonthIncome > 0 || prevMonthExpense > 0) {
      lines.push("")
      lines.push("=== ПРОШЛЫЙ МЕСЯЦ ===")
      lines.push(`Доходы: ${prevMonthIncome}`)
      lines.push(`Расходы: ${prevMonthExpense}`)
      if (prevMonthExpense > 0) {
        const diff = ((monthExpense - prevMonthExpense) / prevMonthExpense * 100).toFixed(0)
        lines.push(`Изменение расходов: ${diff > "0" ? "+" : ""}${diff}%`)
      }
    }

    // Топ категории расходов (текущий месяц)
    const monthExpenses = thisMonth.filter(t => t.type === "expense")
    if (monthExpenses.length > 0) {
      const byCat: Record<string, number> = {}
      for (const t of monthExpenses) {
        byCat[t.category] = (byCat[t.category] ?? 0) + t.amount
      }
      const sorted = Object.entries(byCat).sort((a, b) => b[1] - a[1]).slice(0, 5)
      lines.push("")
      lines.push("=== РАСХОДЫ ПО КАТЕГОРИЯМ (этот месяц) ===")
      for (const [cat, amt] of sorted) {
        const pct = monthExpense > 0 ? ((amt / monthExpense) * 100).toFixed(0) : "0"
        lines.push(`- ${cat}: ${amt} (${pct}%)`)
      }
    }

    // Последние 10 транзакций
    lines.push("")
    lines.push("=== ПОСЛЕДНИЕ 10 ТРАНЗАКЦИЙ ===")
    for (const t of transactions.slice(0, 10)) {
      const d = new Date(t.date).toLocaleDateString("ru-RU")
      lines.push(`- ${d} | ${t.type === "income" ? "+" : "-"}${t.amount} ${t.currency} | ${t.category} | ${t.description || "—"}`)
    }
  } else {
    lines.push("=== НЕТ ТРАНЗАКЦИЙ ===")
    lines.push("У пользователя пока нет транзакций.")
  }

  // Категории
  if (categories.length > 0) {
    lines.push("")
    lines.push("=== КАТЕГОРИИ ===")
    for (const c of categories) {
      lines.push(`- ${c.name} (${c.type})`)
    }
  }

  return lines.join("\n")
}
