import { NextResponse } from "next/server"

const FALLBACK: Record<string, number> = { UZS: 1, USD: 12700, RUB: 140, EUR: 13800 }

export async function GET() {
  try {
    const today = new Date().toISOString().slice(0, 10) // YYYY-MM-DD
    const res = await fetch(`https://cbu.uz/ru/arkhiv-kursov-valyut/json/all/${today}/`, {
      next: { revalidate: 3600 },
    })
    if (!res.ok) throw new Error("CBU API error")
    const data: { Ccy: string; Rate: string; Nominal: string }[] = await res.json()

    const rates: Record<string, number> = { UZS: 1 }
    for (const item of data) {
      const rate = parseFloat(item.Rate) / parseFloat(item.Nominal || "1")
      if (["USD", "RUB", "EUR", "GBP", "CNY", "KZT"].includes(item.Ccy)) {
        rates[item.Ccy] = rate
      }
    }
    return NextResponse.json(rates)
  } catch {
    return NextResponse.json(FALLBACK)
  }
}
