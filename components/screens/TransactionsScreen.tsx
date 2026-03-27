"use client"
import { useEffect, useState } from "react"
import { useStore, type Transaction } from "@/lib/store"
import { X, Search, Trash2, TrendingUp, TrendingDown, Filter } from "lucide-react"

const fmt = (n: number) => n.toLocaleString("ru-RU")

export default function TransactionsScreen({ onClose }: { onClose: () => void }) {
  const { transactions, categories, accounts, fetchTransactions, fetchCategories, deleteTransaction } = useStore()
  const [search, setSearch] = useState("")
  const [filter, setFilter] = useState<"all" | "income" | "expense">("all")
  const [confirmId, setConfirmId] = useState<string | null>(null)
  const [deleting, setDeleting] = useState(false)

  useEffect(() => { fetchTransactions(); fetchCategories() }, [])

  const getCatInfo = (key: string) => {
    if (key === "__receipt__") return { name: "Чек", color: "#f59e0b" }
    const c = categories.find(c => c.icon === key || c.name === key)
    return { name: c?.name ?? key, color: c?.color ?? "#9ca3af" }
  }

  const getAccountName = (id: string) => accounts.find(a => a._id === id)?.name ?? "—"

  const filtered = transactions
    .filter(t => filter === "all" || t.type === filter)
    .filter(t => {
      if (!search) return true
      const s = search.toLowerCase()
      return t.description?.toLowerCase().includes(s) ||
        getCatInfo(t.category).name.toLowerCase().includes(s) ||
        getAccountName(t.accountId).toLowerCase().includes(s)
    })

  // Group by date
  const grouped: [string, Transaction[]][] = []
  const seen: Record<string, number> = {}
  for (const tx of filtered) {
    const key = new Date(tx.date).toLocaleDateString("ru-RU", { day: "numeric", month: "long", year: "numeric" })
    if (seen[key] === undefined) { seen[key] = grouped.length; grouped.push([key, []]) }
    grouped[seen[key]][1].push(tx)
  }

  const handleDelete = async (id: string) => {
    setDeleting(true)
    await deleteTransaction(id)
    setDeleting(false)
    setConfirmId(null)
  }

  return (
    <div className="absolute inset-0 z-50 bg-[#f0f7f4] flex flex-col">
      {/* Header */}
      <div className="bg-white px-5 pt-10 pb-3 border-b border-gray-100">
        <div className="flex items-center justify-between mb-3">
          <p className="text-lg font-bold text-gray-900">История</p>
          <button onClick={onClose} className="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center">
            <X className="w-4 h-4 text-gray-500" />
          </button>
        </div>

        {/* Search */}
        <div className="flex items-center gap-2 bg-gray-50 rounded-xl px-3 py-2 mb-2">
          <Search className="w-4 h-4 text-gray-400 shrink-0" />
          <input value={search} onChange={e => setSearch(e.target.value)}
            placeholder="Поиск..."
            className="flex-1 text-sm outline-none bg-transparent text-gray-700 placeholder:text-gray-400" />
          {search && <button onClick={() => setSearch("")}><X className="w-3.5 h-3.5 text-gray-400" /></button>}
        </div>

        {/* Filter */}
        <div className="flex bg-gray-100 rounded-xl p-0.5">
          {([["all","Все"],["income","Доходы"],["expense","Расходы"]] as const).map(([v, l]) => (
            <button key={v} onClick={() => setFilter(v)}
              className={`flex-1 py-1.5 rounded-lg text-xs font-medium transition-all ${filter === v ? "bg-white text-gray-900 shadow-sm" : "text-gray-500"}`}>
              {l}
            </button>
          ))}
        </div>
      </div>

      {/* List */}
      <div className="flex-1 overflow-y-auto px-4 py-3 space-y-3">
        {filtered.length === 0 ? (
          <div className="flex flex-col items-center py-16 text-gray-400">
            <Filter className="w-10 h-10 mb-2 text-gray-200" />
            <p className="text-sm">Нет транзакций</p>
          </div>
        ) : (
          grouped.map(([date, txs]) => (
            <div key={date} className="bg-white rounded-2xl shadow-sm overflow-hidden">
              <p className="text-xs text-gray-400 font-medium px-4 pt-3 pb-1">{date}</p>
              {txs.map((tx, i) => {
                const { name, color } = getCatInfo(tx.category)
                const isLast = i === txs.length - 1
                return (
                  <div key={tx._id}
                    className={`flex items-center gap-3 px-4 py-3 ${!isLast ? "border-b border-gray-50" : ""}`}>
                    <div className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0"
                      style={{ backgroundColor: color + "22" }}>
                      {tx.type === "income"
                        ? <TrendingUp className="w-4 h-4" style={{ color }} />
                        : <TrendingDown className="w-4 h-4" style={{ color }} />}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-gray-800 truncate">{tx.description || name}</p>
                      <p className="text-xs text-gray-400">{name} · {getAccountName(tx.accountId)}</p>
                    </div>
                    <div className="flex items-center gap-2 shrink-0">
                      <span className={`text-sm font-semibold ${tx.type === "income" ? "text-green-600" : "text-red-500"}`}>
                        {tx.type === "income" ? "+" : "−"}{fmt(tx.amount)}
                      </span>
                      <button onClick={() => setConfirmId(tx._id)}
                        className="w-7 h-7 rounded-lg flex items-center justify-center text-gray-300 hover:text-red-400 hover:bg-red-50 transition-colors">
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                )
              })}
            </div>
          ))
        )}
      </div>

      {/* Delete confirm */}
      {confirmId && (
        <div className="absolute inset-0 bg-black/40 z-50 flex items-end" onClick={() => setConfirmId(null)}>
          <div className="w-full bg-white rounded-t-3xl p-5 space-y-3" onClick={e => e.stopPropagation()}>
            <p className="font-bold text-gray-900 text-base">Удалить транзакцию?</p>
            <p className="text-sm text-gray-400">Баланс счёта будет пересчитан автоматически.</p>
            <div className="flex gap-2 pt-1">
              <button onClick={() => setConfirmId(null)}
                className="flex-1 py-3 bg-gray-100 rounded-xl text-sm font-medium text-gray-700">
                Отмена
              </button>
              <button onClick={() => handleDelete(confirmId)} disabled={deleting}
                className="flex-1 py-3 bg-red-500 rounded-xl text-sm font-medium text-white disabled:opacity-50">
                {deleting ? "Удаление..." : "Удалить"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
