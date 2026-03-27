"use client"
import { useEffect, useState } from "react"
import { useStore, type Currency } from "@/lib/store"
import { ShoppingCart, Car, Clapperboard, Briefcase, Zap, Package, Mic, X, Tag,
  Home, Users, Target, Wallet, Building2, Plane, Heart, Shirt, Coffee, Receipt } from "lucide-react"

const ICON_MAP: Record<string, React.ReactNode> = {
  food: <ShoppingCart className="w-4 h-4" />,
  transport: <Car className="w-4 h-4" />,
  entertainment: <Clapperboard className="w-4 h-4" />,
  salary: <Briefcase className="w-4 h-4" />,
  utilities: <Zap className="w-4 h-4" />,
  other: <Package className="w-4 h-4" />,
  home: <Home className="w-4 h-4" />,
  family: <Users className="w-4 h-4" />,
  target: <Target className="w-4 h-4" />,
  wallet: <Wallet className="w-4 h-4" />,
  bank: <Building2 className="w-4 h-4" />,
  travel: <Plane className="w-4 h-4" />,
  health: <Heart className="w-4 h-4" />,
  clothes: <Shirt className="w-4 h-4" />,
  cafe: <Coffee className="w-4 h-4" />,
  work: <Briefcase className="w-4 h-4" />,
  __receipt__: <Receipt className="w-4 h-4" />,
}

export default function AddTransactionModal({ onClose, initialType = "expense" }: { onClose: () => void; initialType?: "income" | "expense" }) {
  const { accounts, categories, addTransaction, convertAmount, fetchCategories } = useStore()
  const [type, setType] = useState<"income" | "expense">(initialType)
  const [amount, setAmount] = useState("")
  const [currency, setCurrency] = useState<Currency>("UZS")
  const [category, setCategory] = useState("")
  const [description, setDescription] = useState("")
  const [accountId, setAccountId] = useState(accounts[0]?._id ?? "")
  const [saving, setSaving] = useState(false)
  const [voiceActive, setVoiceActive] = useState(false)
  const [convertedAmounts, setConvertedAmounts] = useState<Record<string, number>>({})

  useEffect(() => {
    if (categories.length === 0) fetchCategories()
  }, [])

  // Set default category when categories load or type changes
  useEffect(() => {
    const filtered = categories.filter(c => c.type === type || c.type === "both")
    if (filtered.length > 0 && (!category || !filtered.find(c => c.icon === category))) {
      setCategory(filtered[0].icon)
    }
  }, [categories, type])

  // Voice input
  const handleVoice = async () => {
    if (!("webkitSpeechRecognition" in window || "SpeechRecognition" in window)) {
      alert("Голосовой ввод не поддерживается в этом браузере")
      return
    }
    const SR = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition
    const recognition = new SR()
    recognition.lang = "ru-RU"
    recognition.interimResults = false
    setVoiceActive(true)
    recognition.onresult = async (e: any) => {
      const text = e.results[0][0].transcript
      setVoiceActive(false)
      const res = await fetch("/api/voice", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text }),
      })
      const parsed = await res.json()
      if (parsed.type) setType(parsed.type)
      if (parsed.amount) setAmount(String(parsed.amount))
      if (parsed.currency) setCurrency(parsed.currency)
      if (parsed.category) setCategory(parsed.category)
      if (parsed.description) setDescription(parsed.description)
      if (parsed.accountName) {
        const found = accounts.find((a) => a.name.toLowerCase().includes(parsed.accountName.toLowerCase()))
        if (found) setAccountId(found._id)
      }
    }
    recognition.onerror = () => setVoiceActive(false)
    recognition.start()
  }

  // Currency conversion preview
  const handleAmountChange = (val: string) => {
    setAmount(val)
    const num = parseFloat(val)
    if (!isNaN(num)) {
      const converted: Record<string, number> = {}
      for (const cur of ["UZS", "USD", "RUB"] as Currency[]) {
        if (cur !== currency) converted[cur] = Math.round(convertAmount(num, currency, cur))
      }
      setConvertedAmounts(converted)
    } else {
      setConvertedAmounts({})
    }
  }

  const handleSubmit = async () => {
    if (!amount || !accountId) return
    setSaving(true)
    await addTransaction({
      accountId,
      type,
      amount: parseFloat(amount),
      currency,
      category,
      description,
      date: new Date().toISOString(),
    })
    setSaving(false)
    onClose()
  }

  return (
    <div className="absolute inset-0 bg-black/40 z-50 flex items-end">
      <div className="w-full bg-white rounded-t-3xl p-5 space-y-4 max-h-[85%] overflow-y-auto">
        <div className="flex items-center justify-between">
          <h3 className="font-bold text-gray-900 text-lg">Новая операция</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Type toggle */}
        <div className="flex bg-gray-100 rounded-xl p-1">
          {(["expense", "income"] as const).map((t) => (
            <button key={t} onClick={() => setType(t)}
              className={`flex-1 py-2 rounded-lg text-sm font-medium transition-all ${type === t ? (t === "expense" ? "bg-red-500 text-white" : "bg-green-600 text-white") : "text-gray-500"}`}>
              {t === "expense" ? "Расход" : "Доход"}
            </button>
          ))}
        </div>

        {/* Amount + currency */}
        <div>
          <div className="flex gap-2">
            <input
              type="number"
              placeholder="Сумма"
              value={amount}
              onChange={(e) => handleAmountChange(e.target.value)}
              className="flex-1 border border-gray-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:border-green-400"
            />
            <div className="flex gap-1">
              {(["UZS", "USD", "RUB"] as Currency[]).map((c) => (
                <button key={c} onClick={() => setCurrency(c)}
                  className={`px-2 py-1 rounded-lg text-xs font-medium transition-all ${currency === c ? "bg-green-600 text-white" : "bg-gray-100 text-gray-600"}`}>
                  {c}
                </button>
              ))}
            </div>
          </div>
          {/* Conversion preview */}
          {Object.keys(convertedAmounts).length > 0 && (
            <div className="flex gap-3 mt-1.5">
              {Object.entries(convertedAmounts).map(([cur, val]) => (
                <span key={cur} className="text-xs text-gray-400">≈ {val.toLocaleString("ru-RU")} {cur}</span>
              ))}
            </div>
          )}
        </div>

        {/* Account */}
        <select value={accountId} onChange={(e) => setAccountId(e.target.value)}
          className="w-full border border-gray-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:border-green-400 bg-white">
          {accounts.map((a) => <option key={a._id} value={a._id}>{a.name}</option>)}
        </select>

        {/* Category */}
        <div>
          <p className="text-xs text-gray-400 mb-2">Категория</p>
          {categories.filter(c => c.type === type || c.type === "both").length === 0 ? (
            <div className="flex items-center justify-center py-4 text-gray-400">
              <svg className="w-4 h-4 animate-spin mr-2" viewBox="0 0 24 24" fill="none">
                <circle cx="12" cy="12" r="10" stroke="currentColor" strokeOpacity="0.3" strokeWidth="3"/>
                <path d="M12 2a10 10 0 0 1 10 10" stroke="currentColor" strokeWidth="3" strokeLinecap="round"/>
              </svg>
              <span className="text-sm">Загрузка...</span>
            </div>
          ) : (
            <div className="grid grid-cols-3 gap-2">
              {categories
                .filter(c => c.type === type || c.type === "both")
                .map((c) => (
                  <button key={c.icon} onClick={() => setCategory(c.icon)}
                    className={`flex flex-col items-center gap-1 py-2.5 rounded-xl text-xs transition-all ${category === c.icon ? "text-white" : "bg-gray-50 text-gray-600"}`}
                    style={category === c.icon ? { backgroundColor: c.color } : {}}>
                    <span style={category === c.icon ? { color: "white" } : { color: c.color }}>
                      {ICON_MAP[c.icon] ?? <Tag className="w-4 h-4" />}
                    </span>
                    <span className="truncate w-full text-center px-1 leading-tight">{c.name}</span>
                  </button>
                ))}
            </div>
          )}
        </div>

        {/* Description */}
        <input
          placeholder="Описание (необязательно)"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          className="w-full border border-gray-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:border-green-400"
        />

        {/* Voice button */}
        <button onClick={handleVoice}
          className={`w-full py-2.5 rounded-xl text-sm font-medium flex items-center justify-center gap-2 transition-all ${voiceActive ? "bg-red-100 text-red-600 animate-pulse" : "bg-gray-100 text-gray-600 hover:bg-gray-200"}`}>
          <Mic className="w-4 h-4" />
          {voiceActive ? "Слушаю..." : "Голосовой ввод"}
        </button>

        <button onClick={handleSubmit} disabled={saving || !amount || !accountId}
          className="w-full py-3 bg-green-600 text-white rounded-xl font-semibold text-sm disabled:opacity-50">
          {saving ? "Сохранение..." : "Добавить"}
        </button>
      </div>
    </div>
  )
}
