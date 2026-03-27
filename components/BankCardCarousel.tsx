"use client"
import { useRef, useState, useCallback } from "react"
import { type Account, type Transaction } from "@/lib/store"
import { CreditCard, Home, Users, Briefcase, Target, Wallet, Building2, Plane, TrendingUp, TrendingDown } from "lucide-react"

const ICON_MAP: Record<string, React.ReactNode> = {
  card: <CreditCard className="w-4 h-4" />,
  home: <Home className="w-4 h-4" />,
  family: <Users className="w-4 h-4" />,
  work: <Briefcase className="w-4 h-4" />,
  target: <Target className="w-4 h-4" />,
  wallet: <Wallet className="w-4 h-4" />,
  bank: <Building2 className="w-4 h-4" />,
  travel: <Plane className="w-4 h-4" />,
}

const CARD_WIDTH = 300
const CARD_GAP = 12

function BankCard({ account, transactions }: { account: Account; transactions: Transaction[] }) {
  const fmt = (n: number) => n.toLocaleString("ru-RU")
  const accountTx = transactions.filter((t) => t.accountId === account._id)
  const income = accountTx.filter((t) => t.type === "income").reduce((s, t) => s + t.amount, 0)
  const expense = accountTx.filter((t) => t.type === "expense").reduce((s, t) => s + t.amount, 0)

  return (
    <div
      className="rounded-2xl p-4 flex flex-col gap-3 select-none"
      style={{
        width: CARD_WIDTH,
        minWidth: CARD_WIDTH,
        background: `linear-gradient(135deg, ${account.color}ee, ${account.color}99)`,
        boxShadow: `0 8px 24px ${account.color}44`,
      }}
    >
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2 text-white/90">
          <div className="w-8 h-8 rounded-lg bg-white/20 flex items-center justify-center">
            {ICON_MAP[account.icon] ?? <CreditCard className="w-4 h-4" />}
          </div>
          <span className="font-semibold text-sm">{account.name}</span>
        </div>
        {account.isShared && (
          <span className="text-[10px] bg-white/20 text-white px-2 py-0.5 rounded-full">Совместный</span>
        )}
      </div>

      <div>
        <p className="text-white/60 text-xs mb-1">Баланс</p>
        <p className="text-white text-2xl font-bold">
          {fmt(account.balance)}
          <span className="text-sm font-normal ml-1 text-white/70">{account.currency}</span>
        </p>
      </div>

      <div className="flex gap-3">
        <div className="flex-1 bg-white/15 rounded-xl px-3 py-2 flex items-center gap-2">
          <TrendingUp className="w-4 h-4 text-white/80 shrink-0" />
          <div>
            <p className="text-white/60 text-[10px]">Доходы</p>
            <p className="text-white text-xs font-semibold">{fmt(income)}</p>
          </div>
        </div>
        <div className="flex-1 bg-white/15 rounded-xl px-3 py-2 flex items-center gap-2">
          <TrendingDown className="w-4 h-4 text-white/80 shrink-0" />
          <div>
            <p className="text-white/60 text-[10px]">Расходы</p>
            <p className="text-white text-xs font-semibold">{fmt(expense)}</p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default function BankCardCarousel({
  accounts,
  transactions,
  onAdd,
}: {
  accounts: Account[]
  transactions: Transaction[]
  onAdd?: () => void
}) {
  const [active, setActive] = useState(0)
  const [offset, setOffset] = useState(0)

  // drag state
  const dragging = useRef(false)
  const startX = useRef(0)
  const startOffset = useRef(0)
  const hasMoved = useRef(false)

  const STEP = CARD_WIDTH + CARD_GAP
  const maxIndex = accounts.length - 1

  const snapTo = useCallback(
    (index: number, currentOffset: number) => {
      const clamped = Math.max(0, Math.min(index, maxIndex))
      setActive(clamped)
      setOffset(-clamped * STEP)
    },
    [maxIndex, STEP]
  )

  const onPointerDown = (e: React.PointerEvent) => {
    dragging.current = true
    hasMoved.current = false
    startX.current = e.clientX
    startOffset.current = offset
    ;(e.currentTarget as HTMLElement).setPointerCapture(e.pointerId)
  }

  const onPointerMove = (e: React.PointerEvent) => {
    if (!dragging.current) return
    const dx = e.clientX - startX.current
    if (Math.abs(dx) > 4) hasMoved.current = true
    const raw = startOffset.current + dx
    // rubber-band at edges
    const min = -maxIndex * STEP
    const clamped =
      raw > 0 ? raw * 0.2 : raw < min ? min + (raw - min) * 0.2 : raw
    setOffset(clamped)
  }

  const onPointerUp = (e: React.PointerEvent) => {
    if (!dragging.current) return
    dragging.current = false
    const dx = e.clientX - startX.current
    if (Math.abs(dx) < 5) return // tap, not drag

    if (dx < -40) {
      snapTo(active + 1, offset)
    } else if (dx > 40) {
      snapTo(active - 1, offset)
    } else {
      snapTo(active, offset)
    }
  }

  if (accounts.length === 0) {
    return (
      <div className="flex justify-center px-9 py-2">
        <button
          onClick={onAdd}
          className="w-[300px] h-[158px] rounded-2xl border-2 border-dashed border-gray-200 flex flex-col items-center justify-center gap-2 text-gray-400 hover:border-green-400 hover:text-green-500 transition-all bg-white/60"
        >
          <div className="w-12 h-12 rounded-full border-2 border-dashed border-current flex items-center justify-center">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-6 h-6">
              <line x1="12" y1="5" x2="12" y2="19" strokeLinecap="round" />
              <line x1="5" y1="12" x2="19" y2="12" strokeLinecap="round" />
            </svg>
          </div>
          <p className="text-sm font-medium">Добавить счёт</p>
        </button>
      </div>
    )
  }

  return (
    <div className="space-y-3">
      {/* viewport */}
      <div className="overflow-hidden" style={{ paddingLeft: 37, paddingRight: 37 }}>
        <div
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={onPointerUp}
          onPointerCancel={onPointerUp}
          style={{
            display: "flex",
            gap: CARD_GAP,
            transform: `translateX(${offset}px)`,
            transition: dragging.current ? "none" : "transform 0.35s cubic-bezier(0.25, 1, 0.5, 1)",
            cursor: dragging.current ? "grabbing" : "grab",
            willChange: "transform",
            userSelect: "none",
          }}
        >
          {accounts.map((a) => (
            <BankCard key={a._id} account={a} transactions={transactions} />
          ))}
        </div>
      </div>

      {/* dots */}
      {accounts.length > 1 && (
        <div className="flex justify-center gap-1.5">
          {accounts.map((_, i) => (
            <button
              key={i}
              onClick={() => snapTo(i, offset)}
              style={{
                width: i === active ? 20 : 6,
                height: 6,
                borderRadius: 9999,
                backgroundColor: i === active ? accounts[active]?.color : "#d1d5db",
                transition: "all 0.3s",
                border: "none",
                padding: 0,
              }}
            />
          ))}
        </div>
      )}
    </div>
  )
}
