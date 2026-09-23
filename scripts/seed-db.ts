import dotenv from "dotenv"
import dns from "dns"
import mongoose from "mongoose"

// Force Node.js to use Google DNS (bypasses local DNS issues)
dns.setServers(["8.8.8.8", "1.1.1.1"])
import { User } from "../lib/models/User"
import { Account } from "../lib/models/Account"
import { Category } from "../lib/models/Category"
import { Transaction } from "../lib/models/Transaction"

dotenv.config()

const MONGODB_URI = process.env.MONGODB_URI!

async function seed() {
  console.log("🔌 Connecting to MongoDB...")
  await mongoose.connect(MONGODB_URI)
  console.log("✅ Connected!\n")

  // Clear existing data
  await User.deleteMany({})
  await Account.deleteMany({})
  await Category.deleteMany({})
  await Transaction.deleteMany({})
  console.log("🗑️  Cleared existing collections\n")

  // --- Users ---
  const user = await User.create({
    login: "demo@movo.uz",
    password: "$2b$10$examplehashedpassword123456789",
    name: "Demo User",
    currency: "UZS",
  })
  console.log(`👤 Created user: ${user.login}`)

  const userId = (user._id as mongoose.Types.ObjectId).toString()

  // --- Accounts ---
  const [cash, card, savings] = await Account.create([
    {
      userId,
      name: "Наличные",
      icon: "wallet",
      color: "#22c55e",
      balance: 500000,
      currency: "UZS",
      isShared: false,
    },
    {
      userId,
      name: "Карта UzCard",
      icon: "credit-card",
      color: "#3b82f6",
      balance: 2000000,
      currency: "UZS",
      isShared: false,
    },
    {
      userId,
      name: "Накопления",
      icon: "piggy-bank",
      color: "#f59e0b",
      balance: 500,
      currency: "USD",
      isShared: false,
    },
  ])
  console.log(`🏦 Created ${3} accounts`)

  // --- Categories ---
  const categories = await Category.create([
    { userId, name: "Зарплата",     icon: "briefcase",   color: "#22c55e", type: "income" },
    { userId, name: "Фриланс",      icon: "laptop",      color: "#10b981", type: "income" },
    { userId, name: "Продукты",     icon: "shopping-cart",color: "#f59e0b", type: "expense" },
    { userId, name: "Транспорт",    icon: "car",         color: "#3b82f6", type: "expense" },
    { userId, name: "Рестораны",    icon: "utensils",    color: "#ef4444", type: "expense" },
    { userId, name: "Здоровье",     icon: "heart",       color: "#ec4899", type: "expense" },
    { userId, name: "Развлечения",  icon: "gamepad",     color: "#8b5cf6", type: "expense" },
    { userId, name: "Коммуналка",   icon: "home",        color: "#6b7280", type: "expense" },
  ])
  console.log(`🏷️  Created ${categories.length} categories`)

  const accountId = (cash._id as mongoose.Types.ObjectId).toString()
  const cardId    = (card._id as mongoose.Types.ObjectId).toString()

  // --- Transactions ---
  const now = new Date()
  const transactions = await Transaction.create([
    {
      userId,
      accountId: cardId,
      type: "income",
      amount: 5000000,
      currency: "UZS",
      category: "Зарплата",
      description: "Зарплата за май",
      date: new Date(now.getFullYear(), now.getMonth(), 1),
    },
    {
      userId,
      accountId: cardId,
      type: "income",
      amount: 800000,
      currency: "UZS",
      category: "Фриланс",
      description: "Проект на сайт",
      date: new Date(now.getFullYear(), now.getMonth(), 5),
    },
    {
      userId,
      accountId: accountId,
      type: "expense",
      amount: 120000,
      currency: "UZS",
      category: "Продукты",
      description: "Korzinka",
      date: new Date(now.getFullYear(), now.getMonth(), 7),
    },
    {
      userId,
      accountId: accountId,
      type: "expense",
      amount: 15000,
      currency: "UZS",
      category: "Транспорт",
      description: "Такси",
      date: new Date(now.getFullYear(), now.getMonth(), 8),
    },
    {
      userId,
      accountId: cardId,
      type: "expense",
      amount: 85000,
      currency: "UZS",
      category: "Рестораны",
      description: "Ужин с семьёй",
      date: new Date(now.getFullYear(), now.getMonth(), 10),
    },
    {
      userId,
      accountId: cardId,
      type: "expense",
      amount: 200000,
      currency: "UZS",
      category: "Коммуналка",
      description: "Электричество + газ",
      date: new Date(now.getFullYear(), now.getMonth(), 12),
    },
    {
      userId,
      accountId: cardId,
      type: "expense",
      amount: 50000,
      currency: "UZS",
      category: "Развлечения",
      description: "Кино",
      date: new Date(now.getFullYear(), now.getMonth(), 14),
    },
  ])
  console.log(`💸 Created ${transactions.length} transactions\n`)

  console.log("✅ Seed completed successfully!")
  console.log("📦 Collections created in MongoDB:")
  console.log("   - users")
  console.log("   - accounts")
  console.log("   - categories")
  console.log("   - transactions")

  await mongoose.disconnect()
  process.exit(0)
}

seed().catch((err) => {
  console.error("❌ Seed failed:", err)
  process.exit(1)
})
