import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import { User } from "@/lib/models/User"

export async function POST(req: Request) {
  try {
    await connectDB()
    const { login } = await req.json()
    
    console.log("Checking login availability for:", login)
    
    if (!login) {
      return NextResponse.json({ available: false, error: "Login is required" }, { status: 400 })
    }
    
    const exists = await User.findOne({ login: login.trim() })
    
    console.log("User exists:", !!exists)
    
    if (exists) {
      return NextResponse.json({ available: false }, { status: 200 })
    }
    
    return NextResponse.json({ available: true }, { status: 200 })
  } catch (error) {
    console.error("Check login error:", error)
    return NextResponse.json({ available: false, error: "Server error" }, { status: 500 })
  }
}
