import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Account } from "@/lib/models/Account"
import { Transaction } from "@/lib/models/Transaction"
import { getUserIdFromRequest } from "@/lib/auth"
import { updateAccountSchema, formatZodErrors } from "@/lib/validators"

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await connectDB()

    const userId = getUserIdFromRequest(req)
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })

    const { id: accountId } = await params

    // Убеждаемся, что счёт принадлежит этому пользователю перед удалением.
    // findOneAndDelete атомарно найдёт и удалит только если оба условия совпадают —
    // это предотвращает удаление чужих счетов даже при подмене accountId.
    const deleted = await Account.findOneAndDelete({ _id: accountId, userId })

    if (!deleted) {
      // Счёт не найден или принадлежит другому пользователю — не раскрываем причину
      return NextResponse.json({ error: "Not found" }, { status: 404 })
    }

    // Каскадное удаление всех транзакций удалённого счёта.
    // Дополнительная проверка userId страхует от ситуации, когда транзакции
    // каким-то образом оказались с чужим userId (целостность данных).
    const { deletedCount } = await Transaction.deleteMany({ accountId, userId })

    return NextResponse.json({
      success: true,
      deletedTransactions: deletedCount, // полезно для отладки
    })
  } catch {
    return NextResponse.json({ error: "Failed to delete" }, { status: 500 })
  }
}

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await connectDB()

    const userId = getUserIdFromRequest(req)
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })

    const { id: accountId } = await params
    const rawBody = await req.json()

    // Запрещаем обновлять служебные поля через PATCH
    delete rawBody.userId
    delete rawBody._id

    const parsed = updateAccountSchema.safeParse(rawBody)
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Неверные данные", fields: formatZodErrors(parsed.error) },
        { status: 400 }
      )
    }

    const account = await Account.findOneAndUpdate(
      { _id: accountId, userId },
      parsed.data,
      { new: true }
    )
    if (!account) return NextResponse.json({ error: "Not found" }, { status: 404 })

    return NextResponse.json(account)
  } catch {
    return NextResponse.json({ error: "Failed to update" }, { status: 500 })
  }
}
