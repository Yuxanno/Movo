"use client"
import { useState } from "react"
import { useRouter } from "next/navigation"
import { Eye, EyeOff, User, Lock } from "lucide-react"
import PinScreen from "@/components/PinScreen"
import { pinStore } from "@/lib/pin-store"
import { useStore } from "@/lib/store"

export default function LoginPage() {
  const router = useRouter()
  const setUser = useStore(s => s.setUser)
  const [login, setLogin] = useState("")
  const [password, setPassword] = useState("")
  const [showPass, setShowPass] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")
  const [showPin, setShowPin] = useState(false)

  const handleLogin = async () => {
    if (!login || !password) { setError("Заполните все поля"); return }
    setLoading(true); setError("")
    const res = await fetch("/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ login, password }),
    })
    const data = await res.json()
    setLoading(false)
    if (!res.ok) { setError(data.error ?? "Ошибка входа"); return }
    setUser(data)
    localStorage.setItem("movo_user", JSON.stringify(data))
    if (pinStore.get()) { setShowPin(true) } else { pinStore.setLocked(false); router.push("/") }
  }

  if (showPin) {
    return <PinScreen title="Введите PIN-код" expectedPin={pinStore.get() ?? undefined}
      onSuccess={() => { pinStore.setLocked(false); router.push("/") }}
      onCancel={() => setShowPin(false)} />
  }

  return (
    <div className="flex-1 flex flex-col bg-white">
      {/* Hero */}
      <div className="bg-green-600 px-6 pt-16 pb-20 flex flex-col items-center gap-3">
        <div className="w-20 h-20 bg-white rounded-3xl flex items-center justify-center shadow-lg">
          <svg viewBox="0 0 24 24" fill="none" className="w-10 h-10">
            <path d="M12 2C8 2 5 5 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-4-3-7-7-7z" fill="#16a34a"/>
            <circle cx="12" cy="9" r="2.5" fill="white"/>
          </svg>
        </div>
        <h1 className="text-3xl font-black text-white tracking-tight">Movo</h1>
        <p className="text-green-100 text-sm">Управляй финансами легко</p>
      </div>

      {/* Form */}
      <div className="flex-1 bg-white rounded-t-[2rem] -mt-6 px-6 pt-8 pb-8 flex flex-col justify-between">
        <div className="space-y-5">
          <div>
            <h2 className="text-2xl font-black text-gray-900">Вход</h2>
            <p className="text-sm text-gray-400 mt-1">Войдите в свой аккаунт</p>
          </div>

          {error && (
            <div className="bg-red-50 rounded-2xl px-4 py-3">
              <p className="text-sm text-red-500">{error}</p>
            </div>
          )}

          <div className="space-y-3">
            <div className="flex items-center gap-3 bg-gray-50 rounded-2xl px-4 py-4 border-2 border-transparent focus-within:border-green-500 focus-within:bg-white transition-all">
              <User className="w-4 h-4 text-gray-300 shrink-0" />
              <input type="text" value={login} onChange={e => setLogin(e.target.value)}
                placeholder="Логин"
                className="flex-1 bg-transparent text-sm text-gray-900 outline-none placeholder:text-gray-400" />
            </div>
            <div className="flex items-center gap-3 bg-gray-50 rounded-2xl px-4 py-4 border-2 border-transparent focus-within:border-green-500 focus-within:bg-white transition-all">
              <Lock className="w-4 h-4 text-gray-400 shrink-0" />
              <input type={showPass ? "text" : "password"} value={password} onChange={e => setPassword(e.target.value)}
                placeholder="Пароль"
                className="flex-1 bg-transparent text-sm text-gray-900 outline-none placeholder:text-gray-400" />
              <button onClick={() => setShowPass(!showPass)} className="text-gray-300 shrink-0">
                {showPass ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          <button onClick={handleLogin} disabled={loading}
            className="w-full py-4 bg-green-600 text-white rounded-2xl font-bold text-base flex items-center justify-center disabled:opacity-50 active:scale-[0.98] transition-all shadow-lg shadow-green-200">
            {loading
              ? <svg className="w-5 h-5 animate-spin" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="10" stroke="white" strokeOpacity="0.3" strokeWidth="3"/><path d="M12 2a10 10 0 0 1 10 10" stroke="white" strokeWidth="3" strokeLinecap="round"/></svg>
              : "Войти"}
          </button>
        </div>

        <p className="text-sm text-center text-gray-400 mt-6">
          Нет аккаунта?{" "}
          <button onClick={() => router.push("/register")} className="text-green-600 font-bold">
            Зарегистрироваться
          </button>
        </p>
      </div>
    </div>
  )
}
