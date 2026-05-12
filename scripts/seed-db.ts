/**
 * seed-db.ts — скрипт инициализации пустого MongoDB кластера
 *
 * Создаёт базу данных и все коллекции с правильными индексами.
 *
 * Запуск:
 *   npm run db:seed
 *   — или —
 *   npx ts-node --project tsconfig.scripts.json scripts/seed-db.ts
 */

// eslint-disable-next-line @typescript-eslint/no-require-imports
require("dotenv").config()

import mongoose from "mongoose"

const MONGODB_URI = process.env.MONGODB_URI

if (!MONGODB_URI) {
  console.error("❌ MONGODB_URI не задан в .env")
  process.exit(1)
}

const safeUri = MONGODB_URI.replace(/:([^@]+)@/, ":<password>@")
console.log("🔗 Подключаемся к MongoDB...")
console.log("   URI (masked):", safeUri)

// ─── Schemas ────────────────────────────────────────────────────────────────

const UserSchema = new mongoose.Schema(
  {
    login:    { type: String, required: true, unique: true },
    password: { type: String, required: true },
    name:     { type: String, default: "" },
    currency: { type: String, default: "UZS" },
  },
  { timestamps: true }
)

const AccountSchema = new mongoose.Schema(
  {
    userId:     { type: String, required: true, index: true },
    name:       { type: String, required: true },
    icon:       { type: String, default: "home" },
    color:      { type: String, default: "#22c55e" },
    balance:    { type: Number, default: 0 },
    currency:   { type: String, enum: ["UZS", "USD", "RUB"], default: "UZS" },
    isShared:   { type: Boolean, default: false },
    sharedWith: [{ type: String }],
  },
  { timestamps: true }
)

const CategorySchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    name:   { type: String, required: true },
    icon:   { type: String, default: "tag" },
    color:  { type: String, default: "#22c55e" },
    type:   { type: String, enum: ["income", "expense", "both"], default: "expense" },
  },
  { timestamps: true }
)

const TransactionSchema = new mongoose.Schema(
  {
    userId:      { type: String, required: true, index: true },
    accountId:   { type: String, required: true },
    type:        { type: String, enum: ["income", "expense"], required: true },
    amount:      { type: Number, required: true },
    currency:    { type: String, enum: ["UZS", "USD", "RUB"], default: "UZS" },
    category:    { type: String, default: "other" },
    description: { type: String, default: "" },
    date:        { type: Date, default: Date.now },
  },
  { timestamps: true }
)

// ─── Main ────────────────────────────────────────────────────────────────────

async function main() {
  try {
    console.log("\n⏳ Подключение...")

    // Форсируем Google DNS (фикс ECONNREFUSED при SRV резолве)
    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const dns = require("dns")
      dns.setServers(["8.8.8.8", "8.8.4.4", "1.1.1.1"])
      console.log("🌐 DNS серверы установлены: 8.8.8.8, 8.8.4.4, 1.1.1.1")
    } catch (e) {
      console.warn("⚠️  Не удалось установить DNS серверы:", e)
    }

    const m = await mongoose.connect(MONGODB_URI!, {
      serverSelectionTimeoutMS: 10000,
      connectTimeoutMS: 15000,
      family: 4,
    })
    const connection = m.connection

    console.log("✅ Подключились!")
    console.log("   Host:", connection.host)
    console.log("   Database:", connection.name)

    // Регистрируем модели
    const User        = mongoose.models.User        || mongoose.model("User",        UserSchema)
    const Account     = mongoose.models.Account     || mongoose.model("Account",     AccountSchema)
    const Category    = mongoose.models.Category    || mongoose.model("Category",    CategorySchema)
    const Transaction = mongoose.models.Transaction || mongoose.model("Transaction", TransactionSchema)

    const collections = [
      { model: User,        name: "users" },
      { model: Account,     name: "accounts" },
      { model: Category,    name: "categories" },
      { model: Transaction, name: "transactions" },
    ]

    console.log("\n📂 Создаём коллекции и индексы...\n")

    for (const { model, name } of collections) {
      try {
        await model.createCollection()
        console.log(`  ✅ Коллекция '${name}' — создана`)
      } catch (e: unknown) {
        if ((e as { code?: number }).code === 48) {
          console.log(`  ℹ️  Коллекция '${name}' — уже существует, пропускаем`)
        } else {
          console.error(`  ❌ Ошибка создания коллекции '${name}':`, e)
        }
      }

      try {
        await model.syncIndexes()
        console.log(`  🔑 Индексы '${name}' — синхронизированы`)
      } catch (e) {
        console.error(`  ❌ Ошибка синхронизации индексов '${name}':`, e)
      }
    }

    // Итог
    const existingCollections = await connection.db!.listCollections().toArray()
    console.log("\n📊 Итог — коллекции в базе данных:")
    if (existingCollections.length === 0) {
      console.log("   (пусто — MongoDB создаёт коллекции лениво, при первой записи)")
    } else {
      existingCollections.forEach((c) => console.log("   •", c.name))
    }

    console.log("\n🎉 Инициализация завершена успешно!\n")
  } catch (err: unknown) {
    const error = err as Error & { code?: string; codeName?: string; reason?: unknown }
    console.error("\n❌ ОШИБКА подключения к MongoDB!")
    console.error("   Сообщение:", error.message)
    if (error.code)     console.error("   Код:", error.code)
    if (error.codeName) console.error("   codeName:", error.codeName)
    if (error.reason)   console.error("   Причина выбора сервера:", JSON.stringify(error.reason, null, 2))
    console.error("\n   Стек:\n", error.stack)
    process.exit(1)
  } finally {
    await mongoose.disconnect()
    console.log("🔌 Соединение закрыто.")
  }
}

main()
