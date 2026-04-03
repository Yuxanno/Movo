import { NextResponse } from "next/server"

const FALLBACK: Record<string, number> = { UZS: 1, USD: 12850, RUB: 143, EUR: 13870 }

export async function GET() {
  try {
    // Try NBU.uz first for official commercial rates
    const nbuRes = await fetch("https://nbu.uz/en/exchange-rates/json/", { next: { revalidate: 3600 } })
    if (nbuRes.ok) {
      const data: any[] = await nbuRes.json()
      const rates: Record<string, number> = { UZS: 1 }
      for (const item of data) {
        // NBU provides cb_price, buy, and cell. We use cell for the calculator.
        const rate = parseFloat(item.cb_price || item.nbu_cell_price || "0")
        if (rate > 0 && ["USD", "RUB", "EUR", "GBP", "CNY", "KZT"].includes(item.code)) {
          rates[item.code] = rate
        }
      }
      return NextResponse.json(rates)
    }
  } catch (err) {
    console.warn("NBU API fetch failed, trying CBU:", err)
  }

  try {
    const today = new Date().toISOString().slice(0, 10)
    const cbuRes = await fetch(`https://cbu.uz/ru/arkhiv-kursov-valyut/json/all/${today}/`, { next: { revalidate: 3600 } })
    if (cbuRes.ok) {
      const data: { Ccy: string; Rate: string; Nominal: string }[] = await cbuRes.json()
      const rates: Record<string, number> = { UZS: 1 }
      for (const item of data) {
        const rate = parseFloat(item.Rate) / parseFloat(item.Nominal || "1")
        if (["USD", "RUB", "EUR", "GBP", "CNY", "KZT"].includes(item.Ccy)) {
          rates[item.Ccy] = rate
        }
      }
      return NextResponse.json(rates)
    }
  } catch (err) {
    console.error("CBU API fetch failed:", err)
  }

  return NextResponse.json(FALLBACK)
}
