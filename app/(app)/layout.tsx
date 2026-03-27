"use client"
import { usePathname, useRouter } from "next/navigation"
import { useState, useEffect, createContext } from "react"
import AddTransactionModal from "@/components/screens/AddTransactionModal"
import AddAccountModal from "@/components/screens/AddAccountModal"
import ReceiptScannerModal from "@/components/screens/ReceiptScannerModal"
import TransactionsScreen from "@/components/screens/TransactionsScreen"
import { LangProvider, useLang } from "@/lib/i18n"
import PinScreen from "@/components/PinScreen"
import { pinStore } from "@/lib/pin-store"
import { useStore } from "@/lib/store"

export const ModalContext = createContext({
  openAddAccount: () => {},
  openAddTx: (type?: "income" | "expense") => {},
  openScanner: () => {},
  openHistory: () => {},
})

const NAV_ICONS = [
  { href: "/", icon: <svg viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z" /></svg> },
  { href: "/accounts", icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="w-5 h-5"><rect x="2" y="5" width="20" height="14" rx="2" /><path d="M2 10h20" /><path d="M6 15h4" /></svg> },
  { href: "add", icon: null },
  { href: "/analytics", icon: <svg viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5"><rect x="2" y="13" width="4" height="8" rx="1" /><rect x="9" y="8" width="4" height="13" rx="1" /><rect x="16" y="4" width="4" height="17" rx="1" /></svg> },
  { href: "/profile", icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="w-5 h-5"><circle cx="12" cy="7" r="4" /><path d="M4 21c0-4 3.6-7 8-7s8 3 8 7" strokeLinecap="round" /></svg> },
]

function BottomNav({ onAdd }: { onAdd: (type: "income" | "expense") => void }) {
  const pathname = usePathname()
  const router = useRouter()
  const { t } = useLang()
  const labels = [t.dashboard, t.accounts, "", t.analytics, t.profile]

  return (
    <div className="bg-white border-t border-gray-100 px-4 pt-3 pb-5 shrink-0">
      <div className="flex items-center justify-between">
        {NAV_ICONS.map((item, i) => {
          if (item.href === "add") {
            return (
              <button key="add" onClick={() => onAdd("expense")} className="flex flex-col items-center -mt-8">
                <div className="w-14 h-14 rounded-full bg-green-600 flex items-center justify-center shadow-lg border-4 border-white">
                  <svg viewBox="0 0 24 24" className="w-6 h-6" fill="none">
                    <line x1="12" y1="5" x2="12" y2="19" stroke="white" strokeWidth="2.5" strokeLinecap="round" />
                    <line x1="5" y1="12" x2="19" y2="12" stroke="white" strokeWidth="2.5" strokeLinecap="round" />
                  </svg>
                </div>
              </button>
            )
          }
          const isActive = pathname === item.href
          return (
            <button key={item.href} onClick={() => router.push(item.href)}
              className={`flex flex-col items-center gap-1 px-2 transition-colors ${isActive ? "text-green-600" : "text-gray-400"}`}>
              {item.icon}
              <span className="text-[10px] font-medium">{labels[i]}</span>
            </button>
          )
        })}
      </div>
    </div>
  )
}

function Shell({ children }: { children: React.ReactNode }) {
  const [showAddTx, setShowAddTx] = useState(false)
  const [addTxType, setAddTxType] = useState<"income" | "expense">("expense")
  const [showAddAccount, setShowAddAccount] = useState(false)
  const [showScanner, setShowScanner] = useState(false)
  const [showHistory, setShowHistory] = useState(false)
  const [locked, setLocked] = useState(false)
  const setUser = useStore(s => s.setUser)
  const user = useStore(s => s.user)
  const fetchAccounts = useStore(s => s.fetchAccounts)
  const fetchTransactions = useStore(s => s.fetchTransactions)
  const router = useRouter()

  useEffect(() => {
    if (!user) {
      const saved = localStorage.getItem("movo_user")
      if (saved) {
        const parsed = JSON.parse(saved)
        setUser(parsed)
        // fetch data right after restoring user
        setTimeout(() => {
          useStore.getState().fetchAccounts()
          useStore.getState().fetchTransactions()
          useStore.getState().fetchCategories()
        }, 0)
      } else {
        router.push("/login")
      }
    }
    // Lock on tab hide/show
    const onVisibility = () => {
      if (document.hidden) {
        pinStore.setLocked(true)
      } else {
        if (pinStore.isLocked() && pinStore.get()) {
          setLocked(true)
        }
      }
    }
    document.addEventListener("visibilitychange", onVisibility)
    return () => document.removeEventListener("visibilitychange", onVisibility)
  }, [])

  return (
    <div className="fixed inset-0 bg-gray-700 flex items-center justify-center">
      <div className="w-[375px] h-screen max-h-[812px] bg-[#f0f7f4] shadow-2xl flex flex-col overflow-hidden relative">
        <div className="flex-1 min-h-0 flex flex-col">
        <ModalContext.Provider value={{
          openAddAccount: () => setShowAddAccount(true),
          openAddTx: (type = "expense") => { setAddTxType(type); setShowAddTx(true) },
          openScanner: () => setShowScanner(true),
          openHistory: () => setShowHistory(true),
        }}>
          {children}
        </ModalContext.Provider>
        </div>
        {showAddTx && <AddTransactionModal initialType={addTxType} onClose={() => setShowAddTx(false)} />}
        {showAddAccount && <AddAccountModal onClose={() => setShowAddAccount(false)} />}
        {showScanner && <ReceiptScannerModal onClose={() => setShowScanner(false)} />}
        {showHistory && <TransactionsScreen onClose={() => setShowHistory(false)} />}
        <BottomNav onAdd={(type) => { setAddTxType(type); setShowAddTx(true) }} />
        {locked && pinStore.get() && (
          <PinScreen
            title="Введите PIN-код"
            expectedPin={pinStore.get() ?? undefined}
            onSuccess={() => { pinStore.setLocked(false); setLocked(false) }}
          />
        )}
      </div>
    </div>
  )
}

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <LangProvider>
      <Shell>{children}</Shell>
    </LangProvider>
  )
}
