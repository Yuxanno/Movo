"use client"
import { create } from "zustand"

export interface Account {
  _id: string
  name: string
  icon: string
  color: string
  balance: number
  currency: "UZS" | "USD" | "RUB"
  isShared: boolean
  sharedWith?: string[]
}

export interface Transaction {
  _id: string
  accountId: string
  type: "income" | "expense"
  amount: number
  currency: "UZS" | "USD" | "RUB"
  category: string
  description: string
  date: string
}

export type Currency = "UZS" | "USD" | "RUB"

export interface Category {
  _id: string
  name: string
  icon: string
  color: string
  type: "income" | "expense" | "both"
}

export interface AppUser {
  _id: string
  login: string
  name: string
  currency: string
}

interface AppState {
  user: AppUser | null
  accounts: Account[]
  transactions: Transaction[]
  categories: Category[]
  rates: Record<string, number>
  loading: boolean
  setUser: (user: AppUser | null) => void
  fetchAccounts: () => Promise<void>
  fetchTransactions: (accountId?: string) => Promise<void>
  fetchRates: () => Promise<void>
  fetchCategories: () => Promise<void>
  addAccount: (data: Omit<Account, "_id">) => Promise<void>
  deleteAccount: (id: string) => Promise<void>
  addTransaction: (data: Omit<Transaction, "_id">) => Promise<void>
  deleteTransaction: (id: string) => Promise<void>
  addCategory: (data: Omit<Category, "_id">) => Promise<void>
  deleteCategory: (id: string) => Promise<void>
  convertAmount: (amount: number, from: Currency, to: Currency) => number
}

const authHeaders = (userId: string) => ({
  "Content-Type": "application/json",
  "x-user-id": userId,
})

export const useStore = create<AppState>((set, get) => ({
  user: null,
  accounts: [],
  transactions: [],
  categories: [],
  rates: { UZS: 1, USD: 12700, RUB: 140 },
  loading: false,

  setUser: (user) => set({ user, accounts: [], transactions: [], categories: [] }),

  fetchAccounts: async () => {
    const { user } = get()
    if (!user) return
    set({ loading: true })
    const res = await fetch("/api/accounts", { headers: { "x-user-id": user._id } })
    const data = await res.json()
    set({ accounts: Array.isArray(data) ? data : [], loading: false })
  },

  fetchTransactions: async (accountId) => {
    const { user } = get()
    if (!user) return
    const url = accountId ? `/api/transactions?accountId=${accountId}` : "/api/transactions"
    const res = await fetch(url, { headers: { "x-user-id": user._id } })
    const data = await res.json()
    set({ transactions: Array.isArray(data) ? data : [] })
  },

  fetchRates: async () => {
    const res = await fetch("/api/currency")
    const data = await res.json()
    set({ rates: data })
  },

  fetchCategories: async () => {
    const { user } = get()
    if (!user) return
    const res = await fetch("/api/categories", { headers: { "x-user-id": user._id } })
    const data = await res.json()
    set({ categories: Array.isArray(data) ? data : [] })
  },

  addAccount: async (data) => {
    const { user } = get()
    if (!user) return
    const res = await fetch("/api/accounts", {
      method: "POST",
      headers: authHeaders(user._id),
      body: JSON.stringify(data),
    })
    const account = await res.json()
    set((s) => ({ accounts: [account, ...s.accounts] }))
  },

  deleteAccount: async (id) => {
    const { user } = get()
    if (!user) return
    await fetch(`/api/accounts/${id}`, { method: "DELETE", headers: { "x-user-id": user._id } })
    set((s) => ({ accounts: s.accounts.filter((a) => a._id !== id) }))
  },

  addTransaction: async (data) => {
    const { user } = get()
    if (!user) return
    const res = await fetch("/api/transactions", {
      method: "POST",
      headers: authHeaders(user._id),
      body: JSON.stringify(data),
    })
    const tx = await res.json()
    set((s) => ({
      transactions: [tx, ...s.transactions],
      accounts: s.accounts.map((a) =>
        a._id === data.accountId
          ? { ...a, balance: a.balance + (data.type === "income" ? data.amount : -data.amount) }
          : a
      ),
    }))
  },

  deleteTransaction: async (id) => {
    const { user } = get()
    if (!user) return
    const tx = get().transactions.find(t => t._id === id)
    await fetch(`/api/transactions/${id}`, { method: "DELETE", headers: { "x-user-id": user._id } })
    set((s) => ({
      transactions: s.transactions.filter(t => t._id !== id),
      accounts: tx ? s.accounts.map(a =>
        a._id === tx.accountId
          ? { ...a, balance: a.balance + (tx.type === "income" ? -tx.amount : tx.amount) }
          : a
      ) : s.accounts,
    }))
  },

  addCategory: async (data) => {    const { user } = get()
    if (!user) return
    const res = await fetch("/api/categories", {
      method: "POST",
      headers: authHeaders(user._id),
      body: JSON.stringify(data),
    })
    const cat = await res.json()
    set((s) => ({ categories: [...s.categories, cat] }))
  },

  deleteCategory: async (id) => {
    const { user } = get()
    if (!user) return
    await fetch(`/api/categories/${id}`, { method: "DELETE", headers: { "x-user-id": user._id } })
    set((s) => ({ categories: s.categories.filter((c) => c._id !== id) }))
  },

  convertAmount: (amount, from, to) => {
    const { rates } = get()
    const inUZS = amount * (rates[from] ?? 1)
    return inUZS / (rates[to] ?? 1)
  },
}))
