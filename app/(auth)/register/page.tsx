"use client"
import { useState } from "react"
import { useRouter } from "next/navigation"
import { Eye, EyeOff, ArrowLeft, Check, User, Lock, BadgeCheck } from "lucide-react"
import PinScreen from "@/components/PinScreen"
import { pinStore } from "@/lib/pin-store"
import { useStore } from "@/lib/store"

const STEPS = ["Аккаунт", "Профиль", "PIN-код", "Готово"]

export default function RegisterPage() {
  const router = useRouter()
  const setUser = useStore(s => s.setUser)
  const [step, setStep] = useState(0)
  const [showPass, setShowPass] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")
  const [form, setForm] = useState({ login: "", password: "", confirm: "", name: "", currency: "UZS" })
  const set = (k: keyof typeof form, v: string) => setForm(f => ({ ...f, [k]: v }))

  const handleNext = async () => {
    setError("")
    if (step === 0) {
      if (!form.login || !form.password) { setError("Заполните все поля"); return }
      if (form.password.length < 6) { setError("Пароль минимум 6 символов"); return }
      if (form.password !== form.confirm) { setError("Пароли не совпадают"); return }
      setStep(1)
    } else if (step === 1) {
      if (!form.name) { setError("Введите имя"); return }
      setLoading(true)
      const res = await fetch("/api/auth/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ login: form.login, password: form.password, name: form.name, currency: form.currency }),
      })
      const data = await res.json()
      setLoading(false)
      if (!res.ok) { setError(data.error ?? "Ошибка регистрации"); return }
      setUser(data)
      localStorage.setItem("movo_user", JSON.stringify(data))
      setStep(2)
    } else if (step === 3) {
      router.push("/")
    }
  }

  if (step === 2) {
    return <PinScreen isSetup subtitle="Он будет запрашиваться при каждом входе"
      onSuccess={(pin) => { pinStore.save(pin); pinStore.setLocked(false); setStep(3) }} />
  }

  return (
    <div className="flex-1 flex flex-col bg-white">
      {/* Hero */}
      <div className="bg-green-600 px-6 pt-12 pb-20">
        <div className="flex items-center gap-3 mb-6">
          {step > 0 && (
            <button onClick={() => setStep(s => s - 1)} className="w-9 h-9 bg-white/20 rounded-full flex items-center justify-center">
              <ArrowLeft className="w-4 h-4 text-white" />
            </button>
          )}
          <div>
            <h1 className="text-2xl font-black text-white">Регистрация</h1>
            <p className="text-green-100 text-xs">{STEPS[step]}</p>
          </div>
        </div>
        <div className="flex gap-2">
          {STEPS.map((_, i) => (
            <div key={i} className={`h-1 flex-1 rounded-full transition-all duration-300 ${i <= step ? "bg-white" : "bg-white/25"}`} />
          ))}
        </div>
      </div>

      {/* Form */}
      <div className="flex-1 bg-white rounded-t-[2rem] -mt-6 px-6 pt-8 pb-8 flex flex-col justify-between">
        <div className="space-y-5">
          {error && (
            <div className="bg-red-50 rounded-2xl px-4 py-3">
              <p className="text-sm text-red-500">{error}</p>
            </div>
          )}

          {step === 0 && (
            <>
              <div>
                <h2 className="text-xl font-black text-gray-900">Создайте аккаунт</h2>
                <p className="text-sm text-gray-400 mt-1">Придумайте логин и пароль</p>
              </div>
              <div className="space-y-3">
                <div className="flex items-center gap-3 bg-gray-50 rounded-2xl px-4 py-4 border-2 border-transparent focus-within:border-green-500 focus-within:bg-white transition-all">
                  <User className="w-4 h-4 text-gray-400 shrink-0" />
                  <input type="text" value={form.login} onChange={e => set("login", e.target.value)}
                    placeholder="Логин"
                    className="flex-1 bg-transparent text-sm text-gray-900 outline-none placeholder:text-gray-400" />
                </div>
                <div className="flex items-center gap-3 bg-gray-50 rounded-2xl px-4 py-4 border-2 border-transparent focus-within:border-green-500 focus-within:bg-white transition-all">
                  <Lock className="w-4 h-4 text-gray-400 shrink-0" />
                  <input type={showPass ? "text" : "password"} value={form.password} onChange={e => set("password", e.target.value)}
                    placeholder="Пароль (мин. 6 символов)"
                    className="flex-1 bg-transparent text-sm text-gray-900 outline-none placeholder:text-gray-400" />
                  <button onClick={() => setShowPass(!showPass)} className="text-gray-400 shrink-0">
                    {showPass ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
                <div className="flex items-center gap-3 bg-gray-50 rounded-2xl px-4 py-4 border-2 border-transparent focus-within:border-green-500 focus-within:bg-white transition-all">
                  <BadgeCheck className="w-4 h-4 text-gray-400 shrink-0" />
                  <input type="password" value={form.confirm} onChange={e => set("confirm", e.target.value)}
                    placeholder="Повторите пароль"
                    className="flex-1 bg-transparent text-sm text-gray-900 outline-none placeholder:text-gray-400" />
                </div>
              </div>
            </>
          )}

          {step === 1 && (
            <>
              <div>
                <h2 className="text-xl font-black text-gray-900">О себе</h2>
                <p className="text-sm text-gray-400 mt-1">Имя и основная валюта</p>
              </div>
              <div className="space-y-4">
                <div className="flex items-center gap-3 bg-gray-50 rounded-2xl px-4 py-4 border-2 border-transparent focus-within:border-green-500 focus-within:bg-white transition-all">
                  <User className="w-4 h-4 text-gray-400 shrink-0" />
                  <input value={form.name} onChange={e => set("name", e.target.value)}
                    placeholder="Ваше имя"
                    className="flex-1 bg-transparent text-sm text-gray-900 outline-none placeholder:text-gray-400" />
                </div>
                <div className="grid grid-cols-3 gap-2">
                  {(["UZS", "USD", "RUB"] as const).map(c => (
                    <button key={c} onClick={() => set("currency", c)}
                      className={`py-4 rounded-2xl text-sm font-bold transition-all ${form.currency === c ? "bg-green-600 text-white shadow-lg shadow-green-200" : "bg-gray-50 text-gray-500"}`}>
                      {c}
                    </button>
                  ))}
                </div>
              </div>
            </>
          )}

          {step === 3 && (
            <div className="flex flex-col items-center gap-4 py-8">
              <div className="w-24 h-24 bg-green-100 rounded-full flex items-center justify-center">
                <Check className="w-12 h-12 text-green-600" />
              </div>
              <p className="text-2xl font-black text-gray-900">Готово!</p>
              <p className="text-sm text-gray-400 text-center">Аккаунт создан. Начните управлять своими финансами.</p>
            </div>
          )}
        </div>

        <div className="space-y-3 mt-6">
          <button onClick={handleNext} disabled={loading}
            className="w-full py-4 bg-green-600 text-white rounded-2xl font-bold text-base flex items-center justify-center disabled:opacity-50 active:scale-[0.98] transition-all shadow-lg shadow-green-200">
            {loading
              ? <svg className="w-5 h-5 animate-spin" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="10" stroke="white" strokeOpacity="0.3" strokeWidth="3"/><path d="M12 2a10 10 0 0 1 10 10" stroke="white" strokeWidth="3" strokeLinecap="round"/></svg>
              : step === 3 ? "Начать" : "Далее"}
          </button>
          {step === 0 && (
            <p className="text-sm text-center text-gray-400">
              Уже есть аккаунт?{" "}
              <button onClick={() => router.push("/login")} className="text-green-600 font-bold">Войти</button>
            </p>
          )}
        </div>
      </div>
    </div>
  )
}
