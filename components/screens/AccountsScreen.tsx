"use client"
import { useState, useEffect } from "react"
import { useStore, type Account, type Transaction } from "@/lib/store"
import { CreditCard, Home, Users, Briefcase, Target, Wallet, Building2, Plane, Trash2, Plus, ArrowLeft, TrendingUp, TrendingDown, Search } from "lucide-react"

const ICON_OPTIONS = [
  { id: "card", icon: <CreditCard className="w-5 h-5" /> },
  { id: "home", icon: <Home className="w-5 h-5" /> },
  { id: "family", icon: <Users className="w-5 h-5" /> },
  { id: "work", icon: <Briefcase className="w-5 h-5" /> },
  { id: "target", icon: <Target className="w-5 h-5" /> },
  { id: "wallet", icon: <Wallet className="w-5 h-5" /> },
  { id: "bank", icon: <Building2 className="w-5 h-5" /> },
  { id: "travel", icon: <Plane className="w-5 h-5" /> },
]
const ICON_MAP: Record<string, React.ReactNode> = Object.fromEntries(ICON_OPTIONS.map(i => [i.id, i.icon]))
const COLORS = ["#22c55e", "#6366f1", "#f59e0b", "#ef4444", "#3b82f6", "#8b5cf6", "#ec4899", "#14b8a6"]
const CURRENCIES = ["UZS", "USD", "RUB"] as const

function pickColor(index: number) { return COLORS[index % COLORS.length] }
const fmt = (n: number) => n.toLocaleString("ru-RU")

// ── Transaction row ──────────────────────────────────────────────
function TxRow({ tx, categories }: { tx: Transaction; categories: { name: string; color: string; icon: string }[] }) {
  const cat = categories.find(c => c.name === tx.category || c.icon === tx.category)
  const color = cat?.color ?? (tx.category === "__receipt__" ? "#f59e0b" : "#9ca3af")
  const label = tx.category === "__receipt__" ? "Чек" : (cat?.name ?? tx.category)

  return (
    <div className="flex items-center justify-between py-3 border-b border-gray-50 last:border-0">
      <div className="flex items-center gap-3">
        <div className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0"
          style={{ backgroundColor: color + "22" }}>
          {tx.type === "income"
            ? <TrendingUp className="w-4 h-4" style={{ color }} />
            : <TrendingDown className="w-4 h-4" style={{ color }} />}
        </div>
        <div>
          <p className="text-sm font-medium text-gray-800 leading-tight">
            {tx.description || label}
          </p>
          <p className="text-xs text-gray-400">
            {new Date(tx.date).toLocaleDateString("ru-RU", { day: "numeric", month: "short" })}
            {" · "}{label}
          </p>
        </div>
      </div>
      <span className={`text-sm font-semibold shrink-0 ${tx.type === "income" ? "text-green-600" : "text-red-500"}`}>
        {tx.type === "income" ? "+" : "−"}{fmt(tx.amount)}
      </span>
    </div>
  )
}

// ── Account detail view ──────────────────────────────────────────
function AccountDetail({ account, onBack }: { account: Account; onBack: () => void }) {
  const { transactions, categories, fetchTransactions } = useStore()
  const [filter, setFilter] = useState<"all" | "income" | "expense">("all")
  const [search, setSearch] = useState("")

  useEffect(() => { fetchTransactions(account._id) }, [account._id])

  const txs = transactions
    .filter(t => t.accountId === account._id)
    .filter(t => filter === "all" || t.type === filter)
    .filter(t => !search || t.description?.toLowerCase().includes(search.toLowerCase()) || t.category?.toLowerCase().includes(search.toLowerCase()))

  const income = transactions.filter(t => t.accountId === account._id && t.type === "income").reduce((s, t) => s + t.amount, 0)
  const expense = transactions.filter(t => t.accountId === account._id && t.type === "expense").reduce((s, t) => s + t.amount, 0)

  // Group by date
  const grouped: Record<string, Transaction[]> = {}
  for (const tx of txs) {
    const key = new Date(tx.date).toLocaleDateString("ru-RU", { day: "numeric", month: "long", year: "numeric" })
    if (!grouped[key]) grouped[key] = []
    grouped[key].push(tx)
  }

  return (
    <div className="flex-1 overflow-y-auto">
      {/* Header */}
      <div className="px-5 pt-10 pb-4">
        <button onClick={onBack} className="flex items-center gap-2 text-gray-500 mb-4">
          <ArrowLeft className="w-4 h-4" />
          <span className="text-sm">Назад</span>
        </button>

        {/* Account card */}
        <div className="rounded-2xl p-4 mb-4 text-white"
          style={{ background: `linear-gradient(135deg, ${account.color}ee, ${account.color}99)` }}>
          <div className="flex items-center gap-2 mb-3">
            <div className="w-8 h-8 rounded-lg bg-white/20 flex items-center justify-center">
              {ICON_MAP[account.icon] ?? <CreditCard className="w-4 h-4" />}
            </div>
            <span className="font-semibold">{account.name}</span>
          </div>
          <p className="text-2xl font-bold mb-3">{fmt(account.balance)} <span className="text-sm font-normal opacity-70">{account.currency}</span></p>
          <div className="flex gap-3">
            <div className="flex-1 bg-white/15 rounded-xl px-3 py-2">
              <p className="text-[10px] opacity-70 mb-0.5">Доходы</p>
              <p className="text-sm font-semibold">+{fmt(income)}</p>
            </div>
            <div className="flex-1 bg-white/15 rounded-xl px-3 py-2">
              <p className="text-[10px] opacity-70 mb-0.5">Расходы</p>
              <p className="text-sm font-semibold">−{fmt(expense)}</p>
            </div>
          </div>
        </div>

        {/* Search */}
        <div className="flex items-center gap-2 bg-white rounded-xl px-3 py-2 shadow-sm mb-3">
          <Search className="w-4 h-4 text-gray-400 shrink-0" />
          <input value={search} onChange={e => setSearch(e.target.value)}
            placeholder="Поиск транзакций..."
            className="flex-1 text-sm outline-none bg-transparent text-gray-700 placeholder:text-gray-400" />
        </div>

        {/* Filter tabs */}
        <div className="flex bg-white rounded-xl p-1 shadow-sm mb-4">
          {([["all","Все"],["income","Доходы"],["expense","Расходы"]] as const).map(([val, label]) => (
            <button key={val} onClick={() => setFilter(val)}
              className={`flex-1 py-1.5 rounded-lg text-xs font-medium transition-all ${filter === val ? "bg-green-600 text-white" : "text-gray-500"}`}>
              {label}
            </button>
          ))}
        </div>

        {/* Transactions grouped by date */}
        {txs.length === 0 ? (
          <div className="text-center py-12 text-gray-400">
            <TrendingDown className="w-10 h-10 mx-auto mb-2 text-gray-200" />
            <p className="text-sm">Нет транзакций</p>
          </div>
        ) : (
          <div className="space-y-4">
            {Object.entries(grouped).map(([date, items]) => (
              <div key={date} className="bg-white rounded-2xl px-4 shadow-sm">
                <p className="text-xs text-gray-400 font-medium pt-3 pb-1">{date}</p>
                {items.map(tx => (
                  <TxRow key={tx._id} tx={tx} categories={categories} />
                ))}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

// ── Main accounts list ───────────────────────────────────────────
function AccountCard({ account, onClick, onDelete }: { account: Account; onClick: () => void; onDelete: () => void }) {
  return (
    <div className="bg-white rounded-2xl p-4 shadow-sm" onClick={onClick}>
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl flex items-center justify-center text-white" style={{ backgroundColor: account.color }}>
            {ICON_MAP[account.icon] ?? <CreditCard className="w-5 h-5" />}
          </div>
          <div>
            <p className="font-semibold text-gray-900">{account.name}</p>
            <p className="text-xs text-gray-400">{account.currency}</p>
          </div>
        </div>
        <button onClick={e => { e.stopPropagation(); onDelete() }} className="text-gray-300 hover:text-red-400 transition-colors p-1">
          <Trash2 className="w-4 h-4" />
        </button>
      </div>
      <p className="text-2xl font-bold" style={{ color: account.color }}>
        {fmt(account.balance)} <span className="text-sm font-normal text-gray-400">{account.currency}</span>
      </p>
    </div>
  )
}

export default function AccountsScreen() {
  const { accounts, transactions, addAccount, deleteAccount, fetchAccounts } = useStore()
  const user = useStore(s => s.user)
  const [selected, setSelected] = useState<Account | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ name: "", icon: "card", currency: "UZS" as typeof CURRENCIES[number] })
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState("")

  const handleAdd = async () => {
    if (!form.name.trim()) return
    if (!user) { setError("Сессия истекла"); return }
    setSaving(true)
    setError("")
    try {
      const color = pickColor(accounts.length)
      await addAccount({ ...form, color, balance: 0, isShared: false })
      await fetchAccounts()
      setForm({ name: "", icon: "card", currency: "UZS" })
      setShowForm(false)
    } catch {
      setError("Не удалось создать счёт")
    } finally {
      setSaving(false)
    }
  }

  if (selected) return <AccountDetail account={selected} onBack={() => setSelected(null)} />

  return (
    <div className="flex-1 overflow-y-auto">
      <div className="px-5 pt-10 pb-4">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold text-gray-900">Мои счета</h2>
          <button onClick={() => setShowForm(!showForm)} className="w-9 h-9 bg-green-600 rounded-full flex items-center justify-center text-white shadow-sm">
            <Plus className="w-5 h-5" />
          </button>
        </div>

        {showForm && (
          <div className="bg-white rounded-2xl p-4 shadow-sm mb-4 space-y-3">
            <p className="font-semibold text-gray-900">Новый счёт</p>
            {error && <p className="text-xs text-red-500 bg-red-50 rounded-xl px-3 py-2">{error}</p>}
            <input
              className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm outline-none focus:border-green-400"
              placeholder="Название (Дом, Семья, Бизнес...)"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
            />
            <div>
              <p className="text-xs text-gray-400 mb-2">Иконка</p>
              <div className="flex gap-2 flex-wrap">
                {ICON_OPTIONS.map((ic) => (
                  <button key={ic.id} onClick={() => setForm({ ...form, icon: ic.id })}
                    className={`w-9 h-9 rounded-xl flex items-center justify-center transition-all text-gray-600 ${form.icon === ic.id ? "bg-green-100 ring-2 ring-green-400 text-green-700" : "bg-gray-50"}`}>
                    {ic.icon}
                  </button>
                ))}
              </div>
            </div>
            <div>
              <p className="text-xs text-gray-400 mb-2">Валюта</p>
              <div className="flex gap-2">
                {CURRENCIES.map((cur) => (
                  <button key={cur} onClick={() => setForm({ ...form, currency: cur })}
                    className={`px-3 py-1 rounded-full text-sm font-medium transition-all ${form.currency === cur ? "bg-green-600 text-white" : "bg-gray-100 text-gray-600"}`}>
                    {cur}
                  </button>
                ))}
              </div>
            </div>
            <button onClick={handleAdd} disabled={saving}
              className="w-full py-2.5 bg-green-600 text-white rounded-xl font-medium text-sm disabled:opacity-50">
              {saving ? "Сохранение..." : "Создать счёт"}
            </button>
          </div>
        )}

        <div className="space-y-3">
          {accounts.length === 0 ? (
            <div className="text-center py-12 text-gray-400">
              <CreditCard className="w-12 h-12 mx-auto mb-3 text-gray-300" />
              <p className="text-sm">Нет счетов. Создайте первый!</p>
            </div>
          ) : (
            accounts.map((a) => (
              <AccountCard key={a._id} account={a} onClick={() => setSelected(a)} onDelete={() => deleteAccount(a._id)} />
            ))
          )}
        </div>
      </div>
    </div>
  )
}
