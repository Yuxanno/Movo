import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Category } from "@/lib/models/Category"
import { getUserIdFromRequest } from "@/lib/auth"
import { createCategorySchema, formatZodErrors } from "@/lib/validators"

export async function GET(req: Request) {
  try {
    await connectDB()
    const userId = getUserIdFromRequest(req)
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    const categories = await Category.find({ userId }).sort({ createdAt: 1 })
    const result = categories.map(c => ({
      ...c.toObject(),
      _id: c._id.toString()
    }))
    return NextResponse.json(result)
  } catch {
    return NextResponse.json({ error: "Failed to fetch" }, { status: 500 })
  }
}

export async function POST(req: Request) {
  try {
    await connectDB()
    const userId = getUserIdFromRequest(req)
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    const rawBody = await req.json()
    const parsed = createCategorySchema.safeParse(rawBody)
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Неверные данные", fields: formatZodErrors(parsed.error) },
        { status: 400 }
      )
    }
    const category = await Category.create({ ...parsed.data, userId })
    return NextResponse.json({ ...category.toObject(), _id: category._id.toString() }, { status: 201 })
  } catch {
    return NextResponse.json({ error: "Failed to create" }, { status: 500 })
  }
}
