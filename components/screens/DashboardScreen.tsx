"use client"
import { useEffect, useRef, useState, useContext } from "react"
import { useStore } from "@/lib/store"
import { ShoppingCart, Car, Clapperboard, Briefcase, Zap, Package } from "lucide-react"
import BankCardCarousel from "@/components/BankCardCarousel"
import { ModalContext } from "@/app/(app)/layout"

const CATEGORY_ICONS: Record<string, React.ReactNode> = {
  food: <ShoppingCart className="w-4 h-4" />,
  transport: <Car className="w-4 h-4" />,
  entertainment: <Clapperboard className="w-4 h-4" />,
  salary: <Briefcase className="w-4 h-4" />,
  utilities: <Zap className="w-4 h-4" />,
  other: <Package className="w-4 h-4" />,
}
const CATEGORY_BG: Record<string, string> = {
  food: "#22c55e", transport: "#3b82f6", entertainment: "#f59e0b",
  salary: "#8b5cf6", utilities: "#ef4444", other: "#9ca3af",
}

function FitText({ text, className }: { text: string; className?: string }) {
  const ref = useRef<HTMLParagraphElement>(null)
  const [size, setSize] = useState(32)

  useEffect(() => {
    const el = ref.current
    if (!el) return
    let s = 32
    el.style.fontSize = s + "px"
    while (el.scrollWidth > el.offsetWidth && s > 14) {
      s -= 1
      el.style.fontSize = s + "px"
    }
    setSize(s)
  }, [text])

  return (
    <p ref={ref} className={className} style={{ fontSize: size, whiteSpace: "nowrap", overflow: "hidden" }}>
      {text}
    </p>
  )
}

function SparkLine({ data, color }: { data: number[]; color: string }) {
  const min = Math.min(...data), max = Math.max(...data)
  const w = 60, h = 24
  const pts = data.map((v, i) => {
    const x = (i / (data.length - 1)) * w
    const y = max === min ? h / 2 : h - ((v - min) / (max - min)) * h
    return `${x},${y}`
  }).join(" ")
  return (
    <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`}>
      <polyline fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" points={pts} />
    </svg>
  )
}

function BalanceChart({ data }: { data: number[] }) {
  if (data.length < 2) return <div className="h-[100px] flex items-center justify-center text-xs text-gray-400">Нет данных</div>
  const min = Math.min(...data) * 0.98, max = Math.max(...data) * 1.02
  const w = 320, h = 100
  const pts = data.map((v, i) => ({ x: (i / (data.length - 1)) * w, y: h - ((v - min) / (max - min)) * h }))
  const pathD = pts.map((p, i) => `${i === 0 ? "M" : "L"} ${p.x} ${p.y}`).join(" ")
  const areaD = `${pathD} L ${w} ${h} L 0 ${h} Z`
  return (
    <svg width="100%" viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none" style={{ display: "block" }}>
      <defs>
        <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#22c55e" stopOpacity="0.2" />
          <stop offset="100%" stopColor="#22c55e" stopOpacity="0" />
        </linearGradient>
      </defs>
      <path d={areaD} fill="url(#bg)" />
      <path d={pathD} fill="none" stroke="#22c55e" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

export default function DashboardScreen({ onAddTx }: { onAddTx: () => void }) {
  const { accounts, transactions, fetchAccounts, fetchTransactions } = useStore()
  const { openAddAccount, openAddTx, openScanner, openHistory } = useContext(ModalContext)

  useEffect(() => {
    fetchAccounts()
    fetchTransactions()
  }, [])

  const totalBalance = accounts.reduce((s, a) => s + a.balance, 0)
  const thisMonth = new Date().getMonth()
  const monthTx = transactions.filter((t) => new Date(t.date).getMonth() === thisMonth)
  const income = monthTx.filter((t) => t.type === "income").reduce((s, t) => s + t.amount, 0)
  const expenses = monthTx.filter((t) => t.type === "expense").reduce((s, t) => s + t.amount, 0)

  const balanceTrend = transactions.length > 1
    ? transactions.slice(-13).map((_, i, arr) => {
        return arr.slice(0, i + 1).reduce((s, t) => s + (t.type === "income" ? t.amount : -t.amount), totalBalance - transactions.reduce((s, t) => s + (t.type === "income" ? t.amount : -t.amount), 0))
      })
    : [totalBalance]

  const fmt = (n: number) => n.toLocaleString("ru-RU")

  return (
    <div className="flex-1 overflow-y-auto">
      {/* Header */}
      <div className="px-5 pt-8 pb-4 bg-gradient-to-b from-[#d4ede3] to-[#f0f7f4]">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <svg viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="2" className="w-6 h-6"><path d="M12 2C8 2 5 5 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-4-3-7-7-7z"/><circle cx="12" cy="9" r="2.5"/></svg>
            <span className="text-xl font-bold text-gray-900">Movo</span>
          </div>
          <div className="relative">
            <div className="w-9 h-9 rounded-full bg-white flex items-center justify-center shadow-sm">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-5 h-5 text-gray-600">
                <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
                <path d="M13.73 21a2 2 0 0 1-3.46 0" />
              </svg>
            </div>
          </div>
        </div>
        <div className="flex items-end justify-between gap-2">
          <div className="min-w-0 flex-1">
            <p className="text-sm text-gray-500 mb-1">Общий баланс</p>
            <FitText text={`${fmt(totalBalance)} сум`} className="font-bold text-gray-900 w-full" />
          </div>
          <button className="px-4 py-2 bg-white rounded-full text-sm font-medium text-gray-700 shadow-sm shrink-0">
            Счета
          </button>
        </div>
      </div>

      {/* Bank Cards Carousel */}
      <div className="py-2">
        <BankCardCarousel accounts={accounts} transactions={transactions} onAdd={openAddAccount} />
      </div>

      <div className="px-5 space-y-3 pb-4">
        <div className="bg-white rounded-2xl p-3 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <span className="font-semibold text-gray-900 text-sm">Обзор месяца</span>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-xs text-gray-400 mb-1">Доходы</p>
              <div className="flex items-center gap-2">
                <span className="text-base font-bold text-gray-900">{fmt(income)}</span>
                <SparkLine data={[40, 55, 45, 60, 70, 65, income / 10000 || 80]} color="#22c55e" />
              </div>
            </div>
            <div>
              <p className="text-xs text-gray-400 mb-1">Расходы</p>
              <div className="flex items-center gap-2">
                <span className="text-base font-bold text-gray-900">{fmt(expenses)}</span>
                <SparkLine data={[70, 60, 75, 55, 65, 50, expenses / 10000 || 45]} color="#f97316" />
              </div>
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div>
          <p className="font-semibold text-gray-900 mb-3">Быстрые действия</p>
          <div className="grid grid-cols-4 gap-2">
            {[
              { label: "Доход", icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" className="w-4 h-4"><line x1="12" y1="19" x2="12" y2="5"/><polyline points="5 12 12 5 19 12"/></svg>, action: () => openAddTx("income") },
              { label: "Расход", icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" className="w-4 h-4"><line x1="12" y1="5" x2="12" y2="19"/><polyline points="19 12 12 19 5 12"/></svg>, action: () => openAddTx("expense") },
              { label: "История", icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-4 h-4"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>, action: openHistory },
              { label: "Чек", icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-4 h-4"><rect x="5" y="2" width="14" height="20" rx="2" /><line x1="9" y1="7" x2="15" y2="7" /><line x1="9" y1="11" x2="15" y2="11" /></svg>, action: openScanner },
            ].map((a) => (
              <div key={a.label} className="flex flex-col items-center gap-1.5">
                <button onClick={a.action} className="w-12 h-12 bg-[#e8f5ee] rounded-2xl flex items-center justify-center text-green-700 hover:bg-[#d4ede3] transition-colors">
                  {a.icon}
                </button>
                <span className="text-[10px] text-gray-500 text-center">{a.label}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Balance Trend */}
        <div className="bg-white rounded-2xl p-3 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <span className="font-semibold text-gray-900 text-sm">Динамика баланса</span>
            <span className="text-xs text-gray-400">30 дней</span>
          </div>
          <BalanceChart data={balanceTrend} />
        </div>

        {/* Recent Transactions */}
        <div className="bg-white rounded-2xl p-3 shadow-sm">
          <p className="font-semibold text-gray-900 text-sm mb-2">Последние операции</p>
          {transactions.length === 0 ? (
            <p className="text-sm text-gray-400 text-center py-4">Нет операций</p>
          ) : (
            <div className="space-y-3">
              {transactions.slice(0, 5).map((t) => (
                <div key={t._id} className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-xl flex items-center justify-center text-white" style={{ backgroundColor: CATEGORY_BG[t.category] ?? "#9ca3af" }}>
                      {CATEGORY_ICONS[t.category] ?? <Package className="w-4 h-4" />}
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-800">{t.description || t.category}</p>
                      <p className="text-xs text-gray-400">{new Date(t.date).toLocaleDateString("ru-RU")}</p>
                    </div>
                  </div>
                  <span className={`text-sm font-semibold ${t.type === "income" ? "text-green-600" : "text-red-500"}`}>
                    {t.type === "income" ? "+" : "-"}{fmt(t.amount)}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
