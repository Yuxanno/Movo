import { NextResponse } from "next/server"

// Simple NLP parser for voice input
// Parses phrases like: "Расход 50000 сум на продукты со счета Дом"
export async function POST(req: Request) {
  try {
    const { text } = await req.json()
    if (!text) return NextResponse.json({ error: "No text provided" }, { status: 400 })

    const lower = text.toLowerCase()

    // Detect type
    const type = lower.includes("расход") || lower.includes("потратил") || lower.includes("купил")
      ? "expense"
      : lower.includes("доход") || lower.includes("получил") || lower.includes("зарплата")
      ? "income"
      : "expense"

    // Extract amount
    const amountMatch = text.match(/(\d[\d\s]*\d|\d+)/)
    const amount = amountMatch ? parseInt(amountMatch[0].replace(/\s/g, "")) : 0

    // Detect currency
    const currency = lower.includes("доллар") || lower.includes("usd") || lower.includes("$")
      ? "USD"
      : lower.includes("рубл") || lower.includes("rub")
      ? "RUB"
      : "UZS"

    // Detect category
    const categoryMap: Record<string, string> = {
      продукт: "food", еда: "food", магазин: "food",
      такси: "transport", транспорт: "transport", автобус: "transport",
      кино: "entertainment", ресторан: "entertainment", кафе: "entertainment",
      зарплата: "salary", доход: "salary",
      коммунал: "utilities", свет: "utilities", газ: "utilities",
    }
    let category = "other"
    for (const [key, val] of Object.entries(categoryMap)) {
      if (lower.includes(key)) { category = val; break }
    }

    // Extract account name
    const accountMatch = text.match(/счет[аа]?\s+([А-ЯЁа-яёA-Za-z]+)/i)
    const accountName = accountMatch ? accountMatch[1] : null

    // Extract description (after "на")
    const descMatch = text.match(/на\s+([^со]+?)(?:\s+со\s+|$)/i)
    const description = descMatch ? descMatch[1].trim() : text

    return NextResponse.json({ type, amount, currency, category, description, accountName })
  } catch {
    return NextResponse.json({ error: "Parse failed" }, { status: 500 })
  }
}
