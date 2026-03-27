"use client"
import { useRouter } from "next/navigation"
import DashboardScreen from "@/components/screens/DashboardScreen"

export default function DashboardPage() {
  const router = useRouter()
  // onAddTx не нужен — AddTransactionModal живёт в layout
  return <DashboardScreen onAddTx={() => {}} />
}
