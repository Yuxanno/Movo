"use client"

export const pinStore = {
  save: (pin: string) => {
    if (typeof window !== "undefined") localStorage.setItem("movo_pin", pin)
  },
  get: (): string | null => {
    if (typeof window !== "undefined") return localStorage.getItem("movo_pin")
    return null
  },
  clear: () => {
    if (typeof window !== "undefined") localStorage.removeItem("movo_pin")
  },
  setLocked: (locked: boolean) => {
    if (typeof window !== "undefined") sessionStorage.setItem("movo_locked", locked ? "1" : "0")
  },
  isLocked: (): boolean => {
    if (typeof window !== "undefined") return sessionStorage.getItem("movo_locked") !== "0"
    return true
  },
}
