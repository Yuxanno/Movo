"use client"
import { useState } from "react"
import { useStore } from "@/lib/store"
import { Globe, Lock, ChevronRight, User, Tag, X, Check, LogOut } from "lucide-react"
import { useLang, type Lang } from "@/lib/i18n"
import { useRouter } from "next/navigation"
import { pinStore } from "@/lib/pin-store"
import { useEffect } from "react"

const LANGUAGES: { code: Lang; label: string; flag: string }[] = [
  { code: "ru", label: "Русский", flag: "🇷🇺" },
  { code: "en", label: "English", flag: "🇬🇧" },
  { code: "uz", label: "O'zbek", flag: "🇺🇿" },
]

export default function ProfileScreen({ onOpenCategories }: { onOpenCategories: () => void }) {
  const { accounts, transactions, rates, fetchRates } = useStore()
  const user = useStore(s => s.user)
  const { t, lang, setLang } = useLang()
  const router = useRouter()
  const [showLang, setShowLang] = useState(false)
  const [showSecurity, setShowSecurity] = useState(false)
  const [pinEnabled, setPinEnabled] = useState(() => !!pinStore.get())
  const [biometricEnabled, setBiometricEnabled] = useState(false)
  const [showPinSetup, setShowPinSetup] = useState(false)
  const [showPinDisable, setShowPinDisable] = useState(false)
  const [pin, setPin] = useState("")
  const [pinStep, setPinStep] = useState<"enter" | "confirm">("enter")
  const [pinFirst, setPinFirst] = useState("")
  const [pinError, setPinError] = useState(false)
  const [convertAmounts, setConvertAmounts] = useState<Record<string, string>>({
    USD: "1", USD_uzs: "",
    EUR: "1", EUR_uzs: "",
    RUB: "1", RUB_uzs: "",
  })
  const fmt = (n: number) => n.toLocaleString("ru-RU")
  const totalTx = transactions.length

  useEffect(() => { fetchRates() }, [])

  useEffect(() => {
    if (rates.USD && rates.EUR && rates.RUB) {
      setConvertAmounts(p => ({
        ...p,
        USD_uzs: p.USD_uzs || String(Math.round(rates.USD)),
        EUR_uzs: p.EUR_uzs || String(Math.round(rates.EUR)),
        RUB_uzs: p.RUB_uzs || String(Math.round(rates.RUB)),
      }))
    }
  }, [rates.USD, rates.EUR, rates.RUB])

  const SETTINGS = [
    { icon: <Tag className="w-4 h-4" />, label: t.categories, action: "categories" },
    { icon: <Globe className="w-4 h-4" />, label: t.language, action: "language" },
    { icon: <Lock className="w-4 h-4" />, label: t.security, action: "security" },
  ]

  return (
    <div className="flex-1 overflow-y-auto">
      <div className="px-5 pt-10 pb-4 space-y-4">
        {/* Avatar */}
        <div className="flex flex-col items-center py-6">
          <div className="w-20 h-20 rounded-full bg-green-100 flex items-center justify-center mb-3">
            <User className="w-10 h-10 text-green-600" />
          </div>
          <p className="font-bold text-gray-900 text-lg">{user?.name || user?.login || "—"}</p>
          <p className="text-sm text-gray-400">@{user?.login}</p>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-white rounded-2xl p-3 shadow-sm text-center">
            <p className="text-xl font-bold text-green-600">{accounts.length}</p>
            <p className="text-xs text-gray-400">{t.accounts_count}</p>
          </div>
          <div className="bg-white rounded-2xl p-3 shadow-sm text-center">
            <p className="text-xl font-bold text-green-600">{totalTx}</p>
            <p className="text-xs text-gray-400">{t.operations}</p>
          </div>
        </div>

        {/* Currency rates */}
        <div className="bg-white rounded-2xl p-4 shadow-sm">
          <div className="flex items-center justify-between mb-3">
            <p className="font-semibold text-gray-900">{t.currencyRates}</p>
            <span className="text-[10px] text-gray-400">ЦБ РУз</span>
          </div>
          <div className="space-y-2">
            {[
              { from: "USD", symbol: "$", color: "text-green-600", bg: "bg-green-50" },
              { from: "EUR", symbol: "€", color: "text-blue-600", bg: "bg-blue-50" },
              { from: "RUB", symbol: "₽", color: "text-blue-600", bg: "bg-blue-50" },
            ].map(({ from, symbol, color, bg }) => {
              if (!rates[from]) return null
              const amt = parseFloat(convertAmounts[from]) || 0
              const result = Math.round(amt * rates[from])
              const uzsVal = convertAmounts[from + "_uzs"] ?? String(result)
              return (
                <div key={from} className="flex items-center justify-between py-1 gap-2">
                  <div className="flex items-center gap-2 shrink-0">
                    <div className={`w-7 h-7 rounded-full ${bg} flex items-center justify-center shrink-0`}>
                      <span className={`text-sm font-bold ${color}`}>{symbol}</span>
                    </div>
                    <span className="text-xs text-gray-400">{from}</span>
                  </div>
                  <div className="flex items-center gap-1.5 flex-1 justify-end">
                    <input
                      type="number"
                      inputMode="decimal"
                      value={convertAmounts[from]}
                      onChange={e => {
                        const v = e.target.value
                        const n = parseFloat(v) || 0
                        setConvertAmounts(p => ({ ...p, [from]: v, [from + "_uzs"]: String(Math.round(n * rates[from])) }))
                      }}
                      className="w-16 text-sm font-semibold text-gray-900 text-right bg-transparent border-b border-dashed border-gray-300 focus:border-green-400 outline-none transition-colors pb-0.5"
                    />
                    <span className="text-xs text-gray-400">=</span>
                    <input
                      type="number"
                      inputMode="decimal"
                      value={uzsVal}
                      onChange={e => {
                        const v = e.target.value
                        const n = parseFloat(v) || 0
                        setConvertAmounts(p => ({ ...p, [from + "_uzs"]: v, [from]: String(+(n / rates[from]).toFixed(4)) }))
                      }}
                      className="w-20 text-sm font-semibold text-gray-900 text-right bg-transparent border-b border-dashed border-gray-300 focus:border-green-400 outline-none transition-colors pb-0.5"
                    />
                    <span className="text-xs text-gray-400">UZS</span>
                  </div>
                </div>
              )
            })}
          </div>
        </div>

        {/* Settings */}
        <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
          {SETTINGS.map((item) => (
            <button key={item.label}
              onClick={() => {
                if (item.action === "categories") onOpenCategories()
                if (item.action === "language") setShowLang(true)
                if (item.action === "security") setShowSecurity(true)
              }}
              className="w-full flex items-center justify-between px-4 py-3.5 border-b border-gray-50 last:border-0 hover:bg-gray-50 transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center text-gray-500">{item.icon}</div>
                <span className="text-sm text-gray-700">{item.label}</span>
              </div>
              <div className="flex items-center gap-2">
                {item.action === "language" && (
                  <span className="text-xs text-gray-400">{LANGUAGES.find(l => l.code === lang)?.flag}</span>
                )}
                <ChevronRight className="w-4 h-4 text-gray-300" />
              </div>
            </button>
          ))}
        </div>

        {/* Logout */}
        <button onClick={() => { useStore.getState().setUser(null); localStorage.removeItem("movo_user"); router.push("/login") }}
          className="w-full flex items-center justify-center gap-2 py-3.5 bg-red-50 border border-red-100 rounded-2xl text-red-500 font-medium text-sm transition-all active:scale-95">
          <LogOut className="w-4 h-4" />
          Выйти
        </button>
      </div>

      {/* Security bottom sheet */}
      {showSecurity && (
        <div className="absolute inset-0 bg-black/40 z-50 flex items-end" onClick={() => setShowSecurity(false)}>
          <div className="w-full bg-white rounded-t-3xl p-5 space-y-4" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <p className="font-bold text-gray-900 text-base">{t.security}</p>
              <button onClick={() => setShowSecurity(false)} className="w-7 h-7 bg-gray-100 rounded-full flex items-center justify-center">
                <X className="w-4 h-4 text-gray-500" />
              </button>
            </div>

            {/* PIN toggle */}
            <div className="bg-gray-50 rounded-2xl divide-y divide-gray-100">
              <div className="flex items-center justify-between px-4 py-3.5">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-green-100 flex items-center justify-center">
                    <Lock className="w-4 h-4 text-green-600" />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-gray-800">PIN-код</p>
                    <p className="text-xs text-gray-400">{pinEnabled ? "Включён" : "Выключен"}</p>
                  </div>
                </div>
                <button
                  onClick={() => {
                    if (!pinEnabled) { setShowPinSetup(true); setShowSecurity(false) }
                    else { setShowPinDisable(true); setPin(""); setPinError(false); setShowSecurity(false) }
                  }}
                  className={`w-11 h-6 rounded-full transition-all relative ${pinEnabled ? "bg-green-500" : "bg-gray-300"}`}>
                  <span className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-all ${pinEnabled ? "left-5" : "left-0.5"}`} />
                </button>
              </div>

              {/* Biometric toggle */}
              <div className="flex items-center justify-between px-4 py-3.5">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-blue-100 flex items-center justify-center">
                    <svg viewBox="0 0 24 24" fill="none" stroke="#3b82f6" strokeWidth="1.8" className="w-4 h-4">
                      <path d="M12 2C9 2 6.5 4 6 7" strokeLinecap="round"/>
                      <path d="M18 7c-.5-3-3-5-6-5" strokeLinecap="round"/>
                      <path d="M6 12c0-3.3 2.7-6 6-6s6 2.7 6 6" strokeLinecap="round"/>
                      <path d="M9 12c0-1.7 1.3-3 3-3s3 1.3 3 3" strokeLinecap="round"/>
                      <path d="M12 12v5" strokeLinecap="round"/>
                      <path d="M8 17c1 1.5 5 2 8 0" strokeLinecap="round"/>
                    </svg>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-gray-800">Биометрия</p>
                    <p className="text-xs text-gray-400">Face ID / Touch ID</p>
                  </div>
                </div>
                <button
                  onClick={() => setBiometricEnabled(!biometricEnabled)}
                  className={`w-11 h-6 rounded-full transition-all relative ${biometricEnabled ? "bg-green-500" : "bg-gray-300"}`}>
                  <span className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-all ${biometricEnabled ? "left-5" : "left-0.5"}`} />
                </button>
              </div>
            </div>

            <p className="text-xs text-gray-400 text-center">Данные хранятся только на устройстве</p>
          </div>
        </div>
      )}

      {/* PIN setup sheet */}
      {showPinSetup && (
        <div className="absolute inset-0 bg-black/40 z-50 flex items-end">
          <div className="w-full bg-white rounded-t-3xl p-5 space-y-5">
            <div className="flex items-center justify-between">
              <p className="font-bold text-gray-900 text-base">
                {pinStep === "enter" ? "Введите PIN" : "Повторите PIN"}
              </p>
              <button onClick={() => { setShowPinSetup(false); setPinFirst(""); setPin(""); setPinStep("enter") }}
                className="w-7 h-7 bg-gray-100 rounded-full flex items-center justify-center">
                <X className="w-4 h-4 text-gray-500" />
              </button>
            </div>

            {/* Dots */}
            <div className="flex justify-center gap-4">
              {[0,1,2,3].map((i) => (
                <div key={i} className={`w-4 h-4 rounded-full border-2 transition-all ${pin.length > i ? "bg-green-600 border-green-600" : "border-gray-300"}`} />
              ))}
            </div>

            {/* Numpad */}
            <div className="grid grid-cols-3 gap-3">
              {["1","2","3","4","5","6","7","8","9","","0","⌫"].map((k) => (
                <button key={k} disabled={!k || pin.length >= 4}
                  onClick={() => {
                    if (k === "⌫") { setPin(p => p.slice(0,-1)); return }
                    if (!k) return
                    const next = pin + k
                    setPin(next)
                    if (next.length === 4) {
                      if (pinStep === "enter") {
                        setPinFirst(next); setPin(""); setPinStep("confirm")
                      } else {
                        if (next === pinFirst) {
                          pinStore.save(next)
                          setPinEnabled(true); setShowPinSetup(false)
                          setPinFirst(""); setPin(""); setPinStep("enter")
                        } else {
                          setPin(""); setPinStep("enter"); setPinFirst("")
                        }
                      }
                    }
                  }}
                  className={`h-14 rounded-2xl text-xl font-semibold transition-all
                    ${k === "⌫" ? "bg-gray-100 text-gray-600" : k ? "bg-gray-50 text-gray-900 active:bg-green-50" : ""}`}>
                  {k}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* PIN disable confirmation sheet */}
      {showPinDisable && (
        <div className="absolute inset-0 bg-black/40 z-50 flex items-end">
          <div className="w-full bg-white rounded-t-3xl p-5 space-y-5">
            <div className="flex items-center justify-between">
              <p className="font-bold text-gray-900 text-base">Подтвердите PIN</p>
              <button onClick={() => { setShowPinDisable(false); setPin(""); setPinError(false) }}
                className="w-7 h-7 bg-gray-100 rounded-full flex items-center justify-center">
                <X className="w-4 h-4 text-gray-500" />
              </button>
            </div>
            <p className="text-sm text-gray-400 text-center">Введите текущий PIN чтобы отключить</p>

            <div className="flex justify-center gap-4">
              {[0,1,2,3].map((i) => (
                <div key={i} className={`w-4 h-4 rounded-full border-2 transition-all ${
                  pinError ? "bg-red-400 border-red-400" : pin.length > i ? "bg-green-600 border-green-600" : "border-gray-300"
                }`} />
              ))}
            </div>
            {pinError && <p className="text-xs text-red-500 text-center -mt-2">Неверный PIN</p>}

            <div className="grid grid-cols-3 gap-3">
              {["1","2","3","4","5","6","7","8","9","","0","⌫"].map((k) => (
                <button key={k} disabled={!k || pin.length >= 4}
                  onClick={() => {
                    if (k === "⌫") { setPin(p => p.slice(0,-1)); setPinError(false); return }
                    if (!k) return
                    const next = pin + k
                    setPin(next)
                    if (next.length === 4) {
                      if (next === pinStore.get()) {
                        pinStore.clear()
                        setPinEnabled(false)
                        setShowPinDisable(false)
                        setPin("")
                      } else {
                        setPinError(true)
                        setTimeout(() => { setPin(""); setPinError(false) }, 600)
                      }
                    }
                  }}
                  className={`h-14 rounded-2xl text-xl font-semibold transition-all
                    ${k === "⌫" ? "bg-gray-100 text-gray-600" : k ? "bg-gray-50 text-gray-900 active:bg-green-50" : ""}`}>
                  {k}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Language bottom sheet */}
      {showLang && (
        <div className="absolute inset-0 bg-black/40 z-50 flex items-end" onClick={() => setShowLang(false)}>
          <div className="w-full bg-white rounded-t-3xl p-5" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <p className="font-bold text-gray-900 text-base">{t.chooseLanguage}</p>
              <button onClick={() => setShowLang(false)} className="w-7 h-7 bg-gray-100 rounded-full flex items-center justify-center">
                <X className="w-4 h-4 text-gray-500" />
              </button>
            </div>
            <div className="space-y-2">
              {LANGUAGES.map((l) => (
                <button key={l.code} onClick={() => { setLang(l.code); setShowLang(false) }}
                  className={`w-full flex items-center justify-between px-4 py-3 rounded-2xl transition-all ${lang === l.code ? "bg-green-50 border border-green-200" : "bg-gray-50"}`}>
                  <div className="flex items-center gap-3">
                    <span className="text-2xl">{l.flag}</span>
                    <span className="text-sm font-medium text-gray-800">{l.label}</span>
                  </div>
                  {lang === l.code && <Check className="w-4 h-4 text-green-600" />}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
