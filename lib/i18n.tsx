"use client"
import { createContext, useContext, useState, ReactNode } from "react"

export type Lang = "ru" | "en" | "uz"

export const translations = {
  ru: {
    dashboard: "Dashboard", accounts: "Счета", analytics: "Аналитика", profile: "Профиль",
    totalBalance: "Общий баланс", sum: "сум", monthOverview: "Обзор месяца",
    income: "Доходы", expenses: "Расходы", quickActions: "Быстрые действия",
    expense: "Расход", transfer: "Перевод", voice: "Голос", receipt: "Чек",
    balanceTrend: "Динамика баланса", days30: "30 дней", recentTx: "Последние операции",
    noTx: "Нет операций", categories: "Категории", language: "Язык", security: "Безопасность",
    accounts_count: "Счетов", operations: "Операций", currencyRates: "Курсы валют (ЦБ)",
    addAccount: "Добавить счёт", save: "Сохранить", cancel: "Отмена", delete: "Удалить",
    newTx: "Новая операция", amount: "Сумма", account: "Счёт", category: "Категория",
    description: "Описание", add: "Добавить", saving: "Сохранение...",
    noAccounts: "Нет счетов", noCategories: "Нет категорий",
    monthExpenses: "Расходы за месяц", newCategory: "Новая категория", name: "Название",
    icon: "Иконка", color: "Цвет", currentMonth: "Текущий месяц", categoryList: "Список категорий",
    chooseLanguage: "Выберите язык",
  },
  en: {
    dashboard: "Dashboard", accounts: "Accounts", analytics: "Analytics", profile: "Profile",
    totalBalance: "Total balance", sum: "UZS", monthOverview: "Month overview",
    income: "Income", expenses: "Expenses", quickActions: "Quick actions",
    expense: "Expense", transfer: "Transfer", voice: "Voice", receipt: "Receipt",
    balanceTrend: "Balance trend", days30: "30 days", recentTx: "Recent transactions",
    noTx: "No transactions", categories: "Categories", language: "Language", security: "Security",
    accounts_count: "Accounts", operations: "Transactions", currencyRates: "Exchange rates (CB)",
    addAccount: "Add account", save: "Save", cancel: "Cancel", delete: "Delete",
    newTx: "New transaction", amount: "Amount", account: "Account", category: "Category",
    description: "Description", add: "Add", saving: "Saving...",
    noAccounts: "No accounts", noCategories: "No categories",
    monthExpenses: "Monthly expenses", newCategory: "New category", name: "Name",
    icon: "Icon", color: "Color", currentMonth: "This month", categoryList: "Categories list",
    chooseLanguage: "Choose language",
  },
  uz: {
    dashboard: "Bosh sahifa", accounts: "Hisoblar", analytics: "Tahlil", profile: "Profil",
    totalBalance: "Umumiy balans", sum: "so'm", monthOverview: "Oylik sharh",
    income: "Daromad", expenses: "Xarajatlar", quickActions: "Tezkor amallar",
    expense: "Xarajat", transfer: "O'tkazma", voice: "Ovoz", receipt: "Chek",
    balanceTrend: "Balans dinamikasi", days30: "30 kun", recentTx: "So'nggi operatsiyalar",
    noTx: "Operatsiyalar yo'q", categories: "Kategoriyalar", language: "Til", security: "Xavfsizlik",
    accounts_count: "Hisob", operations: "Operatsiya", currencyRates: "Valyuta kurslari (MB)",
    addAccount: "Hisob qo'shish", save: "Saqlash", cancel: "Bekor qilish", delete: "O'chirish",
    newTx: "Yangi operatsiya", amount: "Miqdor", account: "Hisob", category: "Kategoriya",
    description: "Tavsif", add: "Qo'shish", saving: "Saqlanmoqda...",
    noAccounts: "Hisoblar yo'q", noCategories: "Kategoriyalar yo'q",
    monthExpenses: "Oylik xarajatlar", newCategory: "Yangi kategoriya", name: "Nomi",
    icon: "Belgi", color: "Rang", currentMonth: "Joriy oy", categoryList: "Kategoriyalar ro'yxati",
    chooseLanguage: "Tilni tanlang",
  },
}

type T = typeof translations.ru

interface LangCtx { lang: Lang; t: T; setLang: (l: Lang) => void }

const LangContext = createContext<LangCtx>({ lang: "ru", t: translations.ru, setLang: () => {} })

export function LangProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Lang>("ru")
  const setLang = (l: Lang) => setLangState(l)
  return (
    <LangContext.Provider value={{ lang, t: translations[lang], setLang }}>
      {children}
    </LangContext.Provider>
  )
}

export const useLang = () => useContext(LangContext)
