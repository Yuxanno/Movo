import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { Category } from "@/lib/models/Category"

export async function GET(req: Request) {
  try {
    await connectDB()
    const userId = req.headers.get("x-user-id")
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    const categories = await Category.find({ userId }).sort({ createdAt: 1 })
    // Ensure _id is a string
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
    const userId = req.headers.get("x-user-id")
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    const body = await req.json()
    const category = await Category.create({ ...body, userId })
    return NextResponse.json({ ...category.toObject(), _id: category._id.toString() }, { status: 201 })
  } catch {
    return NextResponse.json({ error: "Failed to create" }, { status: 500 })
  }
}
