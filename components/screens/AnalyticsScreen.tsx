"use client"
import { useEffect, useState } from "react"
import { useStore } from "@/lib/store"
import { TrendingUp, TrendingDown, ArrowUpRight, ArrowDownRight } from "lucide-react"

const fmt = (n: number) => n.toLocaleString("ru-RU")

const MONTH_NAMES = ["Янв","Фев","Мар","Апр","Май","Июн","Июл","Авг","Сен","Окт","Ноя","Дек"]

// ── Bar chart ────────────────────────────────────────────────────
function BarChart({ income, expense }: { income: number[]; expense: number[] }) {
  const max = Math.max(...income, ...expense, 1)
  const now = new Date()
  return (
    <div className="flex items-end gap-1.5 h-28">
      {income.map((inc, i) => {
        const exp = expense[i]
        const monthIdx = (now.getMonth() - 5 + i + 12) % 12
        const isNow = i === 5
        return (
          <div key={i} className="flex-1 flex flex-col items-center gap-1">
            <div className="w-full flex gap-0.5 items-end" style={{ height: 88 }}>
              <div className="flex-1 rounded-t-sm transition-all"
                style={{ height: `${(inc / max) * 88}px`, backgroundColor: isNow ? "#22c55e" : "#22c55e44", minHeight: inc > 0 ? 3 : 0 }} />
              <div className="flex-1 rounded-t-sm transition-all"
                style={{ height: `${(exp / max) * 88}px`, backgroundColor: isNow ? "#ef4444" : "#ef444444", minHeight: exp > 0 ? 3 : 0 }} />
            </div>
            <span className={`text-[9px] ${isNow ? "text-gray-700 font-semibold" : "text-gray-400"}`}>
              {MONTH_NAMES[monthIdx]}
            </span>
          </div>
        )
      })}
    </div>
  )
}

// ── Donut chart ──────────────────────────────────────────────────
function DonutChart({ data }: { data: { value: number; color: string }[] }) {
  const total = data.reduce((s, d) => s + d.value, 0)
  if (total === 0) return <div className="w-24 h-24 rounded-full bg-gray-100 flex items-center justify-center"><span className="text-xs text-gray-400">—</span></div>

  const r = 36, cx = 44, cy = 44, stroke = 14
  const circ = 2 * Math.PI * r
  let offset = 0

  return (
    <svg width="88" height="88" viewBox="0 0 88 88" className="shrink-0">
      <circle cx={cx} cy={cy} r={r} fill="none" stroke="#f3f4f6" strokeWidth={stroke} />
      {data.map((d, i) => {
        const pct = d.value / total
        const dash = pct * circ
        const gap = circ - dash
        const rotate = offset * 360 - 90
        offset += pct
        return (
          <circle key={i} cx={cx} cy={cy} r={r} fill="none"
            stroke={d.color} strokeWidth={stroke}
            strokeDasharray={`${dash} ${gap}`}
            strokeDashoffset={0}
            transform={`rotate(${rotate} ${cx} ${cy})`}
            strokeLinecap="butt"
          />
        )
      })}
    </svg>
  )
}

export default function AnalyticsScreen() {
  const { transactions, categories, fetchTransactions, fetchCategories } = useStore()
  const [period, setPeriod] = useState<"month" | "3m" | "year">("month")

  useEffect(() => { fetchTransactions(); fetchCategories() }, [])

  const now = new Date()
  const periodStart = new Date(now)
  if (period === "month") periodStart.setMonth(now.getMonth() - 1)
  else if (period === "3m") periodStart.setMonth(now.getMonth() - 3)
  else periodStart.setFullYear(now.getFullYear() - 1)

  const filtered = transactions.filter(t => new Date(t.date) >= periodStart)
  const expenses = filtered.filter(t => t.type === "expense")
  const incomes = filtered.filter(t => t.type === "income")

  const totalIncome = incomes.reduce((s, t) => s + t.amount, 0)
  const totalExpense = expenses.reduce((s, t) => s + t.amount, 0)
  const balance = totalIncome - totalExpense

  // Monthly bars (last 6 months)
  const monthlyIncome = Array.from({ length: 6 }, (_, i) => {
    const m = (now.getMonth() - 5 + i + 12) % 12
    const y = now.getFullYear() - (now.getMonth() - 5 + i < 0 ? 1 : 0)
    return transactions.filter(t => {
      const d = new Date(t.date)
      return t.type === "income" && d.getMonth() === m && d.getFullYear() === y
    }).reduce((s, t) => s + t.amount, 0)
  })
  const monthlyExpense = Array.from({ length: 6 }, (_, i) => {
    const m = (now.getMonth() - 5 + i + 12) % 12
    const y = now.getFullYear() - (now.getMonth() - 5 + i < 0 ? 1 : 0)
    return transactions.filter(t => {
      const d = new Date(t.date)
      return t.type === "expense" && d.getMonth() === m && d.getFullYear() === y
    }).reduce((s, t) => s + t.amount, 0)
  })

  // Category breakdown — use categories from store for labels/colors
  const byCategory: Record<string, number> = {}
  for (const t of expenses) {
    if (t.category === "__receipt__") continue
    byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount
  }
  // receipt total
  const receiptTotal = expenses.filter(t => t.category === "__receipt__").reduce((s, t) => s + t.amount, 0)
  if (receiptTotal > 0) byCategory["__receipt__"] = receiptTotal

  const getCatInfo = (key: string) => {
    if (key === "__receipt__") return { name: "Чек", color: "#f59e0b" }
    const c = categories.find(c => c.icon === key || c.name === key)
    return { name: c?.name ?? key, color: c?.color ?? "#9ca3af" }
  }

  const pieData = Object.entries(byCategory)
    .map(([k, v]) => ({ ...getCatInfo(k), value: v }))
    .sort((a, b) => b.value - a.value)

  const topExpenses = pieData.slice(0, 5)

  return (
    <div className="flex-1 overflow-y-auto">
      <div className="px-5 pt-10 pb-6 space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold text-gray-900">Аналитика</h2>
          <div className="flex bg-white rounded-xl p-0.5 shadow-sm text-xs">
            {([["month","1М"],["3m","3М"],["year","Год"]] as const).map(([v, l]) => (
              <button key={v} onClick={() => setPeriod(v)}
                className={`px-2.5 py-1.5 rounded-lg font-medium transition-all ${period === v ? "bg-green-600 text-white" : "text-gray-500"}`}>
                {l}
              </button>
            ))}
          </div>
        </div>

        {/* Balance card */}
        <div className="bg-gradient-to-br from-green-500 to-green-600 rounded-2xl p-4 text-white shadow-lg shadow-green-200">
          <p className="text-xs opacity-80 mb-1">Баланс за период</p>
          <p className="text-2xl font-bold mb-3">{balance >= 0 ? "+" : ""}{fmt(balance)}</p>
          <div className="flex gap-3">
            <div className="flex-1 bg-white/15 rounded-xl px-3 py-2 flex items-center gap-2">
              <ArrowUpRight className="w-4 h-4 shrink-0" />
              <div>
                <p className="text-[10px] opacity-70">Доходы</p>
                <p className="text-sm font-bold">{fmt(totalIncome)}</p>
              </div>
            </div>
            <div className="flex-1 bg-white/15 rounded-xl px-3 py-2 flex items-center gap-2">
              <ArrowDownRight className="w-4 h-4 shrink-0" />
              <div>
                <p className="text-[10px] opacity-70">Расходы</p>
                <p className="text-sm font-bold">{fmt(totalExpense)}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Bar chart */}
        <div className="bg-white rounded-2xl p-4 shadow-sm">
          <div className="flex items-center justify-between mb-3">
            <p className="font-semibold text-gray-900 text-sm">По месяцам</p>
            <div className="flex items-center gap-3 text-[10px] text-gray-400">
              <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-sm bg-green-500 inline-block"/>Доходы</span>
              <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-sm bg-red-400 inline-block"/>Расходы</span>
            </div>
          </div>
          <BarChart income={monthlyIncome} expense={monthlyExpense} />
        </div>

        {/* Category breakdown */}
        <div className="bg-white rounded-2xl p-4 shadow-sm">
          <p className="font-semibold text-gray-900 text-sm mb-3">Расходы по категориям</p>
          {pieData.length === 0 ? (
            <div className="flex flex-col items-center py-6 text-gray-400">
              <TrendingDown className="w-8 h-8 mb-2 text-gray-200" />
              <p className="text-sm">Нет расходов за период</p>
            </div>
          ) : (
            <div className="flex items-center gap-4">
              <DonutChart data={topExpenses.map(d => ({ value: d.value, color: d.color }))} />
              <div className="flex-1 space-y-2.5">
                {topExpenses.map((d) => {
                  const pct = totalExpense > 0 ? Math.round((d.value / totalExpense) * 100) : 0
                  return (
                    <div key={d.name}>
                      <div className="flex items-center justify-between mb-0.5">
                        <div className="flex items-center gap-1.5">
                          <div className="w-2 h-2 rounded-full shrink-0" style={{ backgroundColor: d.color }} />
                          <span className="text-xs text-gray-700 truncate max-w-[90px]">{d.name}</span>
                        </div>
                        <span className="text-xs font-semibold text-gray-800">{pct}%</span>
                      </div>
                      <div className="h-1 bg-gray-100 rounded-full overflow-hidden">
                        <div className="h-full rounded-full transition-all" style={{ width: `${pct}%`, backgroundColor: d.color }} />
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          )}
        </div>

        {/* Top transactions */}
        {expenses.length > 0 && (
          <div className="bg-white rounded-2xl p-4 shadow-sm">
            <p className="font-semibold text-gray-900 text-sm mb-3">Крупные расходы</p>
            <div className="space-y-3">
              {[...expenses].sort((a, b) => b.amount - a.amount).slice(0, 5).map(t => {
                const { name, color } = getCatInfo(t.category)
                return (
                  <div key={t._id} className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-xl flex items-center justify-center shrink-0"
                        style={{ backgroundColor: color + "22" }}>
                        <TrendingDown className="w-4 h-4" style={{ color }} />
                      </div>
                      <div>
                        <p className="text-sm font-medium text-gray-800 leading-tight">{t.description || name}</p>
                        <p className="text-xs text-gray-400">{new Date(t.date).toLocaleDateString("ru-RU", { day: "numeric", month: "short" })}</p>
                      </div>
                    </div>
                    <span className="text-sm font-semibold text-red-500">−{fmt(t.amount)}</span>
                  </div>
                )
              })}
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
