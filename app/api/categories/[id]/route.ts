import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Category } from "@/lib/models/Category"
import { getUserIdFromRequest } from "@/lib/auth"
import { updateCategorySchema, formatZodErrors } from "@/lib/validators"

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await connectDB()
    const userId = getUserIdFromRequest(req)
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    const { id } = await params
    // Удаляем только если категория принадлежит этому пользователю
    await Category.findOneAndDelete({ _id: id, userId })
    return NextResponse.json({ success: true })
  } catch {
    return NextResponse.json({ error: "Failed to delete" }, { status: 500 })
  }
}

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await connectDB()
    const userId = getUserIdFromRequest(req)
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    const { id } = await params
    const rawBody = await req.json()

    // Запрещаем обновлять служебные поля
    delete rawBody.userId
    delete rawBody._id

    const parsed = updateCategorySchema.safeParse(rawBody)
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Неверные данные", fields: formatZodErrors(parsed.error) },
        { status: 400 }
      )
    }

    const category = await Category.findOneAndUpdate(
      { _id: id, userId },
      parsed.data,
      { new: true }
    )
    if (!category) return NextResponse.json({ error: "Not found" }, { status: 404 })

    return NextResponse.json({ ...category.toObject(), _id: category._id.toString() })
  } catch {
    return NextResponse.json({ error: "Failed to update" }, { status: 500 })
  }
}
