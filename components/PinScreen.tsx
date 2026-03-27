"use client"
import { useState } from "react"
import { X } from "lucide-react"

interface Props {
  title?: string
  subtitle?: string
  onSuccess: (pin: string) => void
  onCancel?: () => void
  // If provided, validates against this PIN
  expectedPin?: string
  // If true, shows confirm step after first entry
  isSetup?: boolean
}

export default function PinScreen({ title = "Введите PIN", subtitle, onSuccess, onCancel, expectedPin, isSetup }: Props) {
  const [pin, setPin] = useState("")
  const [step, setStep] = useState<"enter" | "confirm">("enter")
  const [first, setFirst] = useState("")
  const [error, setError] = useState("")
  const [shake, setShake] = useState(false)

  const triggerError = (msg: string) => {
    setError(msg)
    setShake(true)
    setPin("")
    setTimeout(() => setShake(false), 500)
  }

  const handleKey = (k: string) => {
    if (k === "⌫") { setPin(p => p.slice(0, -1)); setError(""); return }
    if (pin.length >= 4) return
    const next = pin + k
    setPin(next)
    if (next.length < 4) return

    if (isSetup) {
      if (step === "enter") {
        setFirst(next)
        setPin("")
        setStep("confirm")
        setError("")
      } else {
        if (next === first) {
          onSuccess(next)
        } else {
          setStep("enter")
          setFirst("")
          triggerError("PIN не совпадает, попробуйте снова")
        }
      }
    } else {
      if (expectedPin && next !== expectedPin) {
        triggerError("Неверный PIN")
      } else {
        onSuccess(next)
      }
    }
  }

  const displayTitle = isSetup
    ? (step === "enter" ? "Создайте PIN-код" : "Повторите PIN-код")
    : title

  return (
    <div className="absolute inset-0 bg-[#f0f7f4] z-50 flex flex-col items-center justify-between py-12 px-6">
      {/* Top */}
      <div className="flex flex-col items-center gap-2 mt-4">
        <div className="w-14 h-14 bg-green-600 rounded-3xl flex items-center justify-center shadow-lg mb-2">
          <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" className="w-7 h-7">
            <path d="M12 2C8 2 5 5 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-4-3-7-7-7z"/>
            <circle cx="12" cy="9" r="2.5"/>
          </svg>
        </div>
        <p className="text-xl font-bold text-gray-900">{displayTitle}</p>
        {subtitle && <p className="text-sm text-gray-400">{subtitle}</p>}
        {error && <p className="text-sm text-red-500 font-medium">{error}</p>}
      </div>

      {/* Dots */}
      <div className={`flex gap-5 ${shake ? "animate-[wiggle_0.4s_ease-in-out]" : ""}`}>
        {[0,1,2,3].map(i => (
          <div key={i} className={`w-5 h-5 rounded-full border-2 transition-all duration-150 ${pin.length > i ? "bg-green-600 border-green-600 scale-110" : "border-gray-300"}`} />
        ))}
      </div>

      {/* Numpad */}
      <div className="w-full max-w-[280px]">
        <div className="grid grid-cols-3 gap-3">
          {["1","2","3","4","5","6","7","8","9","","0","⌫"].map((k, idx) => (
            <button key={idx}
              onClick={() => k && handleKey(k)}
              disabled={!k}
              className={`h-16 rounded-2xl text-xl font-semibold transition-all active:scale-95
                ${k === "⌫" ? "bg-gray-200 text-gray-600" : k ? "bg-white shadow-sm text-gray-900 hover:bg-green-50" : "opacity-0 pointer-events-none"}`}>
              {k}
            </button>
          ))}
        </div>

        {onCancel && (
          <button onClick={onCancel} className="w-full mt-4 py-3 text-sm text-gray-400 flex items-center justify-center gap-1">
            <X className="w-4 h-4" /> Отмена
          </button>
        )}
      </div>
    </div>
  )
}
