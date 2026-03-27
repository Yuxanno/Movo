"use client"
import { useRef, useState } from "react"
import { useStore, type Account } from "@/lib/store"
import { X, Camera, ImageIcon, Loader2, Check, ArrowLeft, Receipt } from "lucide-react"

interface ReceiptItem { name: string; amount: number }
interface ReceiptData {
  items: ReceiptItem[]
  total: number
  currency: string
  store: string | null
  date: string | null
}

// Step 1: choose photo
// Step 2: choose account + type
// Step 3: review & confirm (shows all items as transactions)

type Step = "photo" | "account" | "review"

const ICON_MAP: Record<string, string> = {
  card: "💳", home: "🏠", family: "👨‍👩‍👧", work: "💼",
  target: "🎯", wallet: "👛", bank: "🏦", travel: "✈️",
}

export default function ReceiptScannerModal({ onClose }: { onClose: () => void }) {
  const { accounts, addTransaction } = useStore()
  const fileRef = useRef<HTMLInputElement>(null)
  const cameraRef = useRef<HTMLInputElement>(null)

  const [step, setStep] = useState<Step>("photo")
  const [preview, setPreview] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [receipt, setReceipt] = useState<ReceiptData | null>(null)
  const [error, setError] = useState("")
  const [selectedAccount, setSelectedAccount] = useState<Account | null>(accounts[0] ?? null)
  const [txType, setTxType] = useState<"expense" | "income">("expense")
  const [saving, setSaving] = useState(false)
  const [done, setDone] = useState(false)

  const handleFile = async (file: File) => {
    const reader = new FileReader()
    reader.onload = async (e) => {
      const dataUrl = e.target?.result as string
      setPreview(dataUrl)
      setError("")
      setReceipt(null)
      setLoading(true)
      try {
        const res = await fetch("/api/scan-receipt", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ image: dataUrl }),
        })
        const data = await res.json()
        if (!res.ok) throw new Error(data.error ?? "Ошибка API")
        setReceipt(data)
      } catch (e) {
        setError("Не удалось распознать чек. Попробуйте другое фото.")
        console.error(e)
      } finally {
        setLoading(false)
      }
    }
    reader.readAsDataURL(file)
  }

  const handleSave = async () => {
    if (!receipt || !selectedAccount) return
    setSaving(true)
    const date = receipt.date ? new Date(receipt.date).toISOString() : new Date().toISOString()
    const currency = (["UZS","USD","RUB"].includes(receipt.currency) ? receipt.currency : "UZS") as "UZS"|"USD"|"RUB"

    // Save each item as separate transaction, or total if no items
    const items = receipt.items?.length > 0 ? receipt.items : [{ name: receipt.store ?? "Чек", amount: receipt.total }]
    for (const item of items) {
      await addTransaction({
        accountId: selectedAccount._id,
        type: txType,
        amount: item.amount,
        currency,
        category: "__receipt__",
        description: item.name,
        date,
      })
    }
    setSaving(false)
    setDone(true)
    setTimeout(onClose, 900)
  }

  const fmt = (n: number) => n.toLocaleString("ru-RU")

  return (
    <div className="absolute inset-0 z-50 flex flex-col bg-[#f0f7f4]">
      {/* Header */}
      <div className="flex items-center gap-3 px-5 pt-10 pb-4 bg-white border-b border-gray-100">
        <button onClick={step === "photo" ? onClose : () => setStep(step === "review" ? "account" : "photo")}
          className="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center shrink-0">
          {step === "photo" ? <X className="w-4 h-4 text-gray-500" /> : <ArrowLeft className="w-4 h-4 text-gray-500" />}
        </button>
        <div className="flex-1">
          <p className="font-bold text-gray-900 text-base">
            {step === "photo" ? "Сканировать чек" : step === "account" ? "Выбор счёта" : "Подтверждение"}
          </p>
          <div className="flex gap-1 mt-1">
            {(["photo","account","review"] as Step[]).map((s, i) => (
              <div key={s} className={`h-1 flex-1 rounded-full transition-all ${
                s === step ? "bg-green-500" : i < ["photo","account","review"].indexOf(step) ? "bg-green-300" : "bg-gray-200"
              }`} />
            ))}
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto">

        {/* ── STEP 1: PHOTO ── */}
        {step === "photo" && (
          <div className="px-5 py-5 space-y-4">
            {!preview && !loading && (
              <>
                <button onClick={() => cameraRef.current?.click()}
                  className="w-full py-8 bg-white border-2 border-dashed border-green-200 rounded-2xl flex flex-col items-center gap-3 text-green-600 active:bg-green-50 transition-colors shadow-sm">
                  <div className="w-14 h-14 bg-green-50 rounded-full flex items-center justify-center">
                    <Camera className="w-7 h-7" />
                  </div>
                  <span className="text-sm font-semibold">Сфотографировать</span>
                </button>
                <button onClick={() => fileRef.current?.click()}
                  className="w-full py-6 bg-white border-2 border-dashed border-gray-200 rounded-2xl flex flex-col items-center gap-3 text-gray-500 active:bg-gray-50 transition-colors shadow-sm">
                  <div className="w-12 h-12 bg-gray-50 rounded-full flex items-center justify-center">
                    <ImageIcon className="w-6 h-6" />
                  </div>
                  <span className="text-sm font-semibold">Выбрать из галереи</span>
                </button>
                <input ref={cameraRef} type="file" accept="image/*" capture="environment" className="hidden"
                  onChange={e => e.target.files?.[0] && handleFile(e.target.files[0])} />
                <input ref={fileRef} type="file" accept="image/*" className="hidden"
                  onChange={e => e.target.files?.[0] && handleFile(e.target.files[0])} />
              </>
            )}

            {preview && (
              <div className="relative">
                <img src={preview} alt="Чек" className="w-full rounded-2xl object-contain max-h-56 bg-white shadow-sm" />
                {!loading && (
                  <button onClick={() => { setPreview(null); setReceipt(null); setError("") }}
                    className="absolute top-2 right-2 w-7 h-7 bg-black/50 rounded-full flex items-center justify-center">
                    <X className="w-3.5 h-3.5 text-white" />
                  </button>
                )}
              </div>
            )}

            {loading && (
              <div className="flex flex-col items-center gap-3 py-8">
                <Loader2 className="w-9 h-9 text-green-500 animate-spin" />
                <p className="text-sm text-gray-500 font-medium">Распознаём чек...</p>
              </div>
            )}

            {error && (
              <div className="bg-red-50 rounded-2xl px-4 py-3">
                <p className="text-sm text-red-500">{error}</p>
              </div>
            )}

            {receipt && !loading && (
              <button onClick={() => setStep("account")}
                className="w-full py-3.5 bg-green-600 text-white rounded-2xl font-semibold text-sm shadow-lg shadow-green-200 active:scale-[0.98] transition-all">
                Далее →
              </button>
            )}
          </div>
        )}

        {/* ── STEP 2: ACCOUNT ── */}
        {step === "account" && (
          <div className="px-5 py-5 space-y-4">
            {/* Type */}
            <div className="bg-white rounded-2xl p-1 flex shadow-sm">
              {(["expense","income"] as const).map(type => (
                <button key={type} onClick={() => setTxType(type)}
                  className={`flex-1 py-2.5 rounded-xl text-sm font-semibold transition-all ${
                    txType === type
                      ? type === "expense" ? "bg-red-500 text-white shadow" : "bg-green-500 text-white shadow"
                      : "text-gray-400"
                  }`}>
                  {type === "expense" ? "Расход" : "Доход"}
                </button>
              ))}
            </div>

            {/* Accounts */}
            <p className="text-xs text-gray-400 font-medium px-1">Выберите счёт</p>
            <div className="space-y-2">
              {accounts.map(a => (
                <button key={a._id} onClick={() => setSelectedAccount(a)}
                  className={`w-full flex items-center gap-3 p-4 rounded-2xl border-2 transition-all ${
                    selectedAccount?._id === a._id ? "border-green-400 bg-white shadow-md" : "border-transparent bg-white shadow-sm"
                  }`}>
                  <div className="w-10 h-10 rounded-xl flex items-center justify-center text-white shrink-0"
                    style={{ backgroundColor: a.color }}>
                    <span className="text-lg">{ICON_MAP[a.icon] ?? "💳"}</span>
                  </div>
                  <div className="flex-1 text-left">
                    <p className="text-sm font-semibold text-gray-900">{a.name}</p>
                    <p className="text-xs text-gray-400">{fmt(a.balance)} {a.currency}</p>
                  </div>
                  {selectedAccount?._id === a._id && (
                    <div className="w-5 h-5 bg-green-500 rounded-full flex items-center justify-center shrink-0">
                      <Check className="w-3 h-3 text-white" />
                    </div>
                  )}
                </button>
              ))}
            </div>

            <button onClick={() => setStep("review")} disabled={!selectedAccount}
              className="w-full py-3.5 bg-green-600 text-white rounded-2xl font-semibold text-sm shadow-lg shadow-green-200 disabled:opacity-40 active:scale-[0.98] transition-all">
              Далее →
            </button>
          </div>
        )}

        {/* ── STEP 3: REVIEW ── */}
        {step === "review" && receipt && (
          <div className="px-5 py-5 space-y-4">
            {/* Summary card */}
            <div className="bg-white rounded-2xl p-4 shadow-sm">
              <div className="flex items-center gap-3 mb-3">
                <div className="w-10 h-10 bg-green-50 rounded-xl flex items-center justify-center">
                  <Receipt className="w-5 h-5 text-green-600" />
                </div>
                <div>
                  <p className="text-sm font-bold text-gray-900">{receipt.store ?? "Чек"}</p>
                  <p className="text-xs text-gray-400">
                    {receipt.date ? new Date(receipt.date).toLocaleDateString("ru-RU") : "Сегодня"}
                    {" · "}{selectedAccount?.name}
                    {" · "}<span className={txType === "expense" ? "text-red-500" : "text-green-600"}>{txType === "expense" ? "Расход" : "Доход"}</span>
                  </p>
                </div>
                <div className="ml-auto text-right">
                  <p className={`text-base font-bold ${txType === "expense" ? "text-red-500" : "text-green-600"}`}>
                    {txType === "expense" ? "−" : "+"}{fmt(receipt.total)}
                  </p>
                  <p className="text-xs text-gray-400">{receipt.currency}</p>
                </div>
              </div>
            </div>

            {/* Items list */}
            {receipt.items?.length > 0 && (
              <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
                <p className="text-xs text-gray-400 font-medium px-4 pt-3 pb-2">Позиции ({receipt.items.length})</p>
                {receipt.items.map((item, i) => (
                  <div key={i} className={`flex items-center justify-between px-4 py-3 ${i < receipt.items.length - 1 ? "border-b border-gray-50" : ""}`}>
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-gray-100 rounded-lg flex items-center justify-center">
                        <Receipt className="w-4 h-4 text-gray-400" />
                      </div>
                      <span className="text-sm text-gray-800 max-w-[160px] truncate">{item.name}</span>
                    </div>
                    <span className={`text-sm font-semibold ${txType === "expense" ? "text-red-500" : "text-green-600"}`}>
                      {txType === "expense" ? "−" : "+"}{fmt(item.amount)}
                    </span>
                  </div>
                ))}
                <div className="flex justify-between px-4 py-3 bg-gray-50 border-t border-gray-100">
                  <span className="text-sm font-bold text-gray-900">Итого</span>
                  <span className={`text-sm font-bold ${txType === "expense" ? "text-red-500" : "text-green-600"}`}>
                    {txType === "expense" ? "−" : "+"}{fmt(receipt.total)} {receipt.currency}
                  </span>
                </div>
              </div>
            )}

            <button onClick={handleSave} disabled={saving || done}
              className="w-full py-3.5 bg-green-600 text-white rounded-2xl font-semibold text-sm flex items-center justify-center gap-2 shadow-lg shadow-green-200 disabled:opacity-50 active:scale-[0.98] transition-all">
              {done
                ? <><Check className="w-4 h-4" /> Сохранено</>
                : saving
                ? <Loader2 className="w-4 h-4 animate-spin" />
                : `Сохранить ${receipt.items?.length > 1 ? `${receipt.items.length} транзакции` : "транзакцию"}`}
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
