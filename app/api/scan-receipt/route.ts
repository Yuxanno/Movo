import { NextResponse } from "next/server"

export async function POST(req: Request) {
  try {
    const { image } = await req.json()
    if (!image) return NextResponse.json({ error: "No image" }, { status: 400 })

    const apiKey = process.env.GROQ_API
    if (!apiKey) return NextResponse.json({ error: "GROQ_API key not set" }, { status: 500 })

    // Compress: if base64 is too large (>3MB raw), reject early
    const base64Data = image.split(",")[1] ?? image
    const sizeBytes = Math.ceil(base64Data.length * 0.75)
    if (sizeBytes > 3.5 * 1024 * 1024) {
      return NextResponse.json({ error: "Изображение слишком большое. Используйте фото меньшего размера." }, { status: 413 })
    }

    const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: "meta-llama/llama-4-scout-17b-16e-instruct",
        response_format: { type: "json_object" },
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: `Ты анализируешь фото чека или квитанции. Извлеки данные и верни JSON:
{
  "items": [{ "name": "название товара/услуги", "amount": число }],
  "total": число,
  "currency": "UZS",
  "store": "название магазина или null",
  "date": "YYYY-MM-DD или null"
}
Правила: суммы — числа без пробелов и символов. Если валюта не определена — UZS. Если позиции не видны — items пустой массив. total обязателен.`,
              },
              {
                type: "image_url",
                image_url: { url: image },
              },
            ],
          },
        ],
        max_tokens: 1024,
        temperature: 0.1,
      }),
    })

    const responseText = await res.text()

    if (!res.ok) {
      console.error("Groq error:", responseText)
      return NextResponse.json({ error: `Groq API: ${res.status} ${responseText.slice(0, 200)}` }, { status: 500 })
    }

    const data = JSON.parse(responseText)
    const content = data.choices?.[0]?.message?.content ?? "{}"
    const parsed = JSON.parse(content)

    // Ensure total is a number
    if (!parsed.total || isNaN(parsed.total)) {
      parsed.total = parsed.items?.reduce((s: number, i: { amount: number }) => s + (i.amount || 0), 0) ?? 0
    }

    return NextResponse.json(parsed)
  } catch (e) {
    console.error("scan-receipt error:", e)
    return NextResponse.json({ error: String(e) }, { status: 500 })
  }
}
