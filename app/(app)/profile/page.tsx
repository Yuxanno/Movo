"use client"
import { useState } from "react"
import ProfileScreen from "@/components/screens/ProfileScreen"
import CategoriesScreen from "@/components/screens/CategoriesScreen"

export default function ProfilePage() {
  const [showCategories, setShowCategories] = useState(false)

  return (
    <>
      <ProfileScreen onOpenCategories={() => setShowCategories(true)} />
      {showCategories && (
        <div className="absolute inset-0 z-50 bg-[#f0f7f4]">
          <CategoriesScreen onClose={() => setShowCategories(false)} />
        </div>
      )}
    </>
  )
}
