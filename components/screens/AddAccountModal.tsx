"use client"
import { useState } from "react"
import { useStore } from "@/lib/store"
import { CreditCard, Home, Users, Briefcase, Target, Wallet, Building2, Plane, X } from "lucide-react"

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
const COLORS = ["#22c55e", "#6366f1", "#f59e0b", "#ef4444", "#3b82f6", "#8b5cf6", "#ec4899", "#14b8a6"]
const CURRENCIES = ["UZS", "USD", "RUB"] as const

export default function AddAccountModal({ onClose }: { onClose: () => void }) {
  const { accounts, addAccount, fetchAccounts } = useStore()
  const user = useStore(s => s.user)
  const [form, setForm] = useState({ name: "", icon: "card", currency: "UZS" as typeof CURRENCIES[number] })
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState("")

  const handleAdd = async () => {
    if (!form.name.trim()) return
    if (!user) { setError("Сессия истекла. Перезайдите в аккаунт."); return }
    setSaving(true)
    setError("")
    try {
      const color = COLORS[accounts.length % COLORS.length]
      await addAccount({ ...form, color, balance: 0, isShared: false })
      await fetchAccounts()
      onClose()
    } catch {
      setError("Не удалось создать счёт. Попробуйте ещё раз.")
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="absolute inset-0 z-50 flex flex-col justify-end bg-black/40" onClick={onClose}>
      <div className="bg-white rounded-t-2xl p-5 space-y-4" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between">
          <p className="font-semibold text-gray-900">Новый счёт</p>
          <button onClick={onClose}><X className="w-5 h-5 text-gray-400" /></button>
        </div>

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

        <button onClick={handleAdd} disabled={saving || !form.name.trim()}
          className="w-full py-2.5 bg-green-600 text-white rounded-xl font-medium text-sm disabled:opacity-50">
          {saving ? "Сохранение..." : "Создать счёт"}
        </button>
      </div>
    </div>
  )
}
