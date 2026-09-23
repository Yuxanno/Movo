import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Transaction } from "@/lib/models/Transaction"
import { Account } from "@/lib/models/Account"
import { getUserIdFromRequest } from "@/lib/auth"
import { createTransactionSchema, formatZodErrors } from "@/lib/validators"

export async function GET(req: Request) {
  try {
    await connectDB()
    const userId = getUserIdFromRequest(req)
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })

    const { searchParams } = new URL(req.url)
    const accountId = searchParams.get("accountId")
    const filter: Record<string, string> = { userId }
    if (accountId) filter.accountId = accountId

    const transactions = await Transaction.find(filter).sort({ date: -1 }).limit(50)
    return NextResponse.json(transactions)
  } catch {
    return NextResponse.json({ error: "Failed to fetch" }, { status: 500 })
  }
}

export async function POST(req: Request) {
  try {
    const mongooseConn = await connectDB()
    const userId = getUserIdFromRequest(req)
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })

    const rawBody = await req.json()

    // ── Валидация входящих данных через Zod ───────────────────────────────────
    // Если body невалиден — возвращаем 400 с детальным описанием ошибок.
    // До базы данных запрос не доходит.
    const parsed = createTransactionSchema.safeParse(rawBody)
    if (!parsed.success) {
      return NextResponse.json(
        {
          error: "Неверные данные",
          // Плоский объект { поле: "сообщение" } — удобен для показа в UI
          fields: formatZodErrors(parsed.error),
        },
        { status: 400 }
      )
    }

    const body = parsed.data

    const session = await mongooseConn.startSession()
    let tx;

    try {
      await session.withTransaction(async () => {
        // Убеждаемся, что счёт принадлежит этому пользователю.
        // Без этой проверки злоумышленник мог бы подменить accountId и изменить
        // баланс чужого счёта.
        const account = await Account.findOne({ _id: body.accountId, userId }).session(session)
        if (!account) {
          // Abort the transaction
          throw new Error("Account not found")
        }

        // Создаём транзакцию с проверенными данными + userId из JWT (не из body)
        const txResult = await Transaction.create([{ ...body, userId }], { session })
        tx = txResult[0]

        // Обновляем баланс счёта атомарно
        const delta = body.type === "income" ? body.amount : -body.amount
        await Account.findByIdAndUpdate(body.accountId, { $inc: { balance: delta } }, { session })
      })

      return NextResponse.json(tx, { status: 201 })
    } finally {
      session.endSession()
    }
  } catch (error) {
    if (error instanceof Error && error.message === "Account not found") {
      return NextResponse.json(
        { error: "Счёт не найден или не принадлежит пользователю" },
        { status: 404 }
      )
    }
    return NextResponse.json({ error: "Failed to create" }, { status: 500 })
  }
}
