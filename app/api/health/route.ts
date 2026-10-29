import { NextResponse } from "next/server"
import { connectDB } from "@/lib/db"
import mongoose from "mongoose"

export async function GET() {
  const start = Date.now()

  try {
    await connectDB()

    // Лёгкий пинг к MongoDB — не делает реального запроса, просто проверяет соединение
    await mongoose.connection.db?.admin().ping()

    return NextResponse.json({
      status: "ok",
      db: "connected",
      latency_ms: Date.now() - start,
      timestamp: new Date().toISOString(),
    })
  } catch (err) {
    return NextResponse.json(
      {
        status: "error",
        db: "disconnected",
        error: err instanceof Error ? err.message : "unknown",
        timestamp: new Date().toISOString(),
      },
      { status: 503 }
    )
  }
}
