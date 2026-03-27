"use client"
import { useRouter } from "next/navigation"
import CategoriesScreen from "@/components/screens/CategoriesScreen"

export default function CategoriesPage() {
  const router = useRouter()
  return <CategoriesScreen onClose={() => router.push("/profile")} />
}
