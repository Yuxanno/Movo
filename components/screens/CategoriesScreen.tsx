"use client"
import { useEffect, useState } from "react"
import { useStore, type Category } from "@/lib/store"
import {
  ShoppingCart, Car, Clapperboard, Briefcase, Zap,
  UtensilsCrossed, Plane, Heart, GraduationCap, Home, Gift,
  Shirt, Dumbbell, Music, Coffee, Tag, Trash2, Plus, X
} from "lucide-react"

const ICON_OPTIONS = [
  { id: "shopping-cart", icon: <ShoppingCart className="w-5 h-5" /> },
  { id: "car", icon: <Car className="w-5 h-5" /> },
  { id: "film", icon: <Clapperboard className="w-5 h-5" /> },
  { id: "briefcase", icon: <Briefcase className="w-5 h-5" /> },
  { id: "zap", icon: <Zap className="w-5 h-5" /> },
  { id: "utensils", icon: <UtensilsCrossed className="w-5 h-5" /> },
  { id: "plane", icon: <Plane className="w-5 h-5" /> },
  { id: "heart", icon: <Heart className="w-5 h-5" /> },
  { id: "graduation", icon: <GraduationCap className="w-5 h-5" /> },
  { id: "home", icon: <Home className="w-5 h-5" /> },
  { id: "gift", icon: <Gift className="w-5 h-5" /> },
  { id: "shirt", icon: <Shirt className="w-5 h-5" /> },
  { id: "dumbbell", icon: <Dumbbell className="w-5 h-5" /> },
  { id: "music", icon: <Music className="w-5 h-5" /> },
  { id: "coffee", icon: <Coffee className="w-5 h-5" /> },
  { id: "tag", icon: <Tag className="w-5 h-5" /> },
]
const ICON_MAP = Object.fromEntries(ICON_OPTIONS.map((i) => [i.id, i.icon]))
const COLORS = ["#22c55e", "#6366f1", "#f59e0b", "#ef4444", "#3b82f6", "#8b5cf6", "#ec4899", "#14b8a6", "#f97316", "#64748b"]
const TYPE_LABELS = { expense: "Расход", income: "Доход" }

function CategoryRow({ cat, total, monthTotal, onDelete }: {
  cat: Category
  total: number
  monthTotal: number
  onDelete: () => void
}) {
  const fmt = (n: number) => n.toLocaleString("ru-RU")
  return (
    <div className="flex items-center gap-3 bg-white rounded-2xl px-4 py-3 shadow-sm">
      {/* Icon */}
      <div className="w-12 h-12 rounded-2xl flex items-center justify-center shrink-0" style={{ backgroundColor: cat.color + "22", color: cat.color }}>
        {ICON_MAP[cat.icon] ?? <Tag className="w-5 h-5" />}
      </div>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <p className="font-semibold text-gray-900 text-sm">{cat.name}</p>
        <p className="text-xs text-gray-400">Текущий месяц</p>
      </div>

      {/* Amounts */}
      <div className="text-right shrink-0">
        <p className="font-semibold text-gray-900 text-sm">{fmt(total)}</p>
        <p className="text-xs font-medium" style={{ color: cat.color }}>
          {monthTotal > 0 ? `-${fmt(monthTotal)}` : "—"}
        </p>
      </div>

      {/* Delete */}
      <button onClick={onDelete} className="text-red-400 hover:text-red-600 transition-colors ml-1">
        <Trash2 className="w-3.5 h-3.5" />
      </button>
    </div>
  )
}

// Simple donut chart
function DonutChart({ data }: { data: { value: number; color: string }[] }) {
  const total = data.reduce((s, d) => s + d.value, 0)
  if (total === 0) return <div className="w-24 h-24 rounded-full bg-gray-100" />
  let angle = -90
  const cx = 48, cy = 48, r = 38
  const slices = data.map((d) => {
    const pct = d.value / total
    const start = angle
    angle += pct * 360
    const toRad = (a: number) => (a * Math.PI) / 180
    const x1 = cx + r * Math.cos(toRad(start))
    const y1 = cy + r * Math.sin(toRad(start))
    const x2 = cx + r * Math.cos(toRad(angle))
    const y2 = cy + r * Math.sin(toRad(angle))
    return { ...d, path: `M ${cx} ${cy} L ${x1} ${y1} A ${r} ${r} 0 ${pct > 0.5 ? 1 : 0} 1 ${x2} ${y2} Z` }
  })
  return (
    <svg viewBox="0 0 96 96" className="w-24 h-24">
      {slices.map((s, i) => <path key={i} d={s.path} fill={s.color} />)}
      <circle cx={cx} cy={cy} r="22" fill="white" />
    </svg>
  )
}

export default function CategoriesScreen({ onClose }: { onClose: () => void }) {
  const { categories, transactions, fetchCategories, addCategory, deleteCategory } = useStore()
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ name: "", icon: "tag", color: "#22c55e", type: "expense" as "expense" | "income" })
  const [saving, setSaving] = useState(false)
  const [filter, setFilter] = useState<"expense" | "income">("expense")

  const user = useStore(s => s.user)

  useEffect(() => {
    fetchCategories().then(async () => {
      // If still empty after fetch — seed defaults
      const cats = useStore.getState().categories
      if (cats.length === 0 && user) {
        await fetch("/api/auth/seed-categories", {
          method: "POST",
          headers: { "Content-Type": "application/json", "x-user-id": user._id },
        })
        fetchCategories()
      }
    })
  }, [])
  const handleAdd = async () => {
    if (!form.name.trim()) return
    setSaving(true)
    await addCategory(form)
    setSaving(false)
    setForm({ name: "", icon: "tag", color: "#22c55e", type: "expense" })
    setShowForm(false)
  }

  const now = new Date()
  const thisMonth = now.getMonth()
  const thisYear = now.getFullYear()

  // Total spent per category (all time) — match by icon
  const totalByCategory = (cat: { name: string; icon: string }) =>
    transactions.filter((t) => (t.category === cat.icon || t.category === cat.name) && t.type === "expense").reduce((s, t) => s + t.amount, 0)

  // Spent this month per category
  const monthByCategory = (cat: { name: string; icon: string }) =>
    transactions.filter((t) => {
      const d = new Date(t.date)
      return (t.category === cat.icon || t.category === cat.name) && t.type === "expense" && d.getMonth() === thisMonth && d.getFullYear() === thisYear
    }).reduce((s, t) => s + t.amount, 0)

  const totalExpenses = transactions
    .filter((t) => { const d = new Date(t.date); return t.type === "expense" && d.getMonth() === thisMonth && d.getFullYear() === thisYear })
    .reduce((s, t) => s + t.amount, 0)

  const filtered = categories.filter((c) => c.type === filter && c.icon !== "__receipt__")

  const donutData = filtered.map((c) => ({ value: monthByCategory(c) || 1, color: c.color }))

  const fmt = (n: number) => n.toLocaleString("ru-RU")

  return (
    <div className="absolute inset-0 bg-[#f0f7f4] z-40 flex flex-col">
      {/* Header */}
      <div className="px-5 pt-10 pb-3 flex items-center justify-between">
        <h2 className="text-xl font-bold text-gray-900">Категории</h2>
        <div className="flex items-center gap-2">
          <button onClick={() => setShowForm(!showForm)} className="w-8 h-8 bg-green-600 rounded-full flex items-center justify-center text-white">
            <Plus className="w-4 h-4" />
          </button>
          <button onClick={onClose} className="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center text-gray-500">
            <X className="w-4 h-4" />
          </button>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-5 space-y-3 pb-4">

        {/* Summary card */}
        <div className="bg-white rounded-2xl p-4 shadow-sm">
          <p className="font-bold text-gray-900 text-base mb-3">
            Расходы за месяц: <span className="text-green-600">{fmt(totalExpenses)}</span>
          </p>
          <div className="flex items-center gap-4">
            <DonutChart data={donutData} />
            <div className="flex-1 space-y-1.5">
              {filtered.slice(0, 4).map((c) => {
                const val = monthByCategory(c)
                const pct = totalExpenses > 0 ? Math.round((val / totalExpenses) * 100) : 0
                return (
                  <div key={c._id} className="flex items-center gap-2">
                    <div className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: c.color }} />
                    <span className="text-xs text-gray-600 flex-1 truncate">{c.name}</span>
                    <span className="text-xs font-semibold text-gray-700">{pct}%</span>
                  </div>
                )
              })}
            </div>
          </div>
        </div>

        {/* Filter */}
        <div className="flex bg-white rounded-xl p-1 shadow-sm">
          {(["expense", "income"] as const).map((f) => (
            <button key={f} onClick={() => setFilter(f)}
              className={`flex-1 py-1.5 rounded-lg text-xs font-medium transition-all ${filter === f ? "bg-green-600 text-white" : "text-gray-500"}`}>
              {f === "expense" ? "Расходы" : "Доходы"}
            </button>
          ))}
        </div>

        {/* Categories list */}
        <div>
          <p className="font-semibold text-gray-900 text-sm mb-2">Список категорий</p>
          <div className="space-y-2">
            {filtered.length === 0 ? (
              <div className="text-center py-10 text-gray-400">
                <Tag className="w-10 h-10 mx-auto mb-2 text-gray-300" />
                <p className="text-sm">Нет категорий</p>
              </div>
            ) : (
              filtered.map((cat) => (
                <CategoryRow
                  key={cat._id}
                  cat={cat}
                  total={totalByCategory(cat)}
                  monthTotal={monthByCategory(cat)}
                  onDelete={() => deleteCategory(cat._id)}
                />
              ))
            )}
          </div>
        </div>
      </div>

      {/* Add Category Bottom Sheet */}
      {showForm && (
        <div className="absolute inset-0 bg-black/40 z-50 flex items-end" onClick={() => setShowForm(false)}>
          <div className="w-full bg-white rounded-t-3xl p-5 space-y-4" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-1">
              <p className="font-bold text-gray-900 text-base">Новая категория</p>
              <button onClick={() => setShowForm(false)} className="w-7 h-7 bg-gray-100 rounded-full flex items-center justify-center">
                <X className="w-4 h-4 text-gray-500" />
              </button>
            </div>
            <input
              className="w-full border border-gray-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:border-green-400"
              placeholder="Название"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
            />
            <div className="flex gap-2">
              {(["expense", "income"] as const).map((t) => (
                <button key={t} onClick={() => setForm({ ...form, type: t })}
                  className={`flex-1 py-2 rounded-xl text-sm font-medium transition-all ${form.type === t ? "bg-green-600 text-white" : "bg-gray-100 text-gray-600"}`}>
                  {TYPE_LABELS[t]}
                </button>
              ))}
            </div>
            <div>
              <p className="text-xs text-gray-400 mb-2">Иконка</p>
              <div className="grid grid-cols-8 gap-1.5">
                {ICON_OPTIONS.map((ic) => (
                  <button key={ic.id} onClick={() => setForm({ ...form, icon: ic.id })}
                    className={`w-9 h-9 rounded-xl flex items-center justify-center transition-all ${form.icon === ic.id ? "ring-2 ring-green-400" : "bg-gray-50 text-gray-500"}`}
                    style={form.icon === ic.id ? { backgroundColor: form.color + "22", color: form.color } : {}}>
                    {ic.icon}
                  </button>
                ))}
              </div>
            </div>
            <div>
              <p className="text-xs text-gray-400 mb-2">Цвет</p>
              <div className="flex gap-2 flex-wrap">
                {COLORS.map((c) => (
                  <button key={c} onClick={() => setForm({ ...form, color: c })}
                    className={`w-7 h-7 rounded-full transition-all ${form.color === c ? "ring-2 ring-offset-2 ring-gray-400" : ""}`}
                    style={{ backgroundColor: c }} />
                ))}
              </div>
            </div>
            <button onClick={handleAdd} disabled={saving || !form.name.trim()}
              className="w-full py-3 bg-red-500 text-white rounded-xl text-sm font-semibold disabled:opacity-50">
              {saving ? "Сохранение..." : "Добавить"}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
