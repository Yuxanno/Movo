import { NextResponse } from "next/server"

export async function POST(req: Request) {
  try {
    let base64Image = ""
    let mimeType = "image/jpeg"

    // Check content type to decide how to parse
    const contentType = req.headers.get("content-type") || ""
    
    if (contentType.includes("multipart/form-data")) {
      const formData = await req.formData()
      const file = formData.get("file") as File | null
      if (!file) return NextResponse.json({ error: "No file uploaded" }, { status: 400 })
      
      const bytes = await file.arrayBuffer()
      const buffer = Buffer.from(bytes)
      base64Image = buffer.toString("base64")
      mimeType = file.type || "image/jpeg"
    } else {
      const { image } = await req.json()
      if (!image) return NextResponse.json({ error: "No image provided" }, { status: 400 })
      // Handle data:image/jpeg;base64,...
      const match = image.match(/^data:([^;]+);base64,(.+)$/)
      if (match) {
        mimeType = match[1]
        base64Image = match[2]
      } else {
        base64Image = image
      }
    }

    const xaiKey = process.env.XAI_API_KEY
    const groqKey = process.env.GROQ_API

    let apiUrl = ""
    let apiKey = ""
    let model = ""

    if (xaiKey) {
      apiUrl = "https://api.x.ai/v1/chat/completions"
      apiKey = xaiKey
      model = "grok-vision-beta" // or grok-2-vision-1212
    } else if (groqKey) {
      apiUrl = "https://api.groq.com/openai/v1/chat/completions"
      apiKey = groqKey
      model = "llama-3.2-11b-vision-preview"
    } else {
      return NextResponse.json({ error: "No vision API key configured (XAI_API_KEY or GROQ_API)" }, { status: 500 })
    }

    const dataUrl = `data:${mimeType};base64,${base64Image}`

    const res = await fetch(apiUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: `Ты — профессиональный финансовый помощник. Проанализируй фото чека и извлеки данные в формате JSON:
{
  "items": [{ "name": "название товара", "price": число }],
  "totalAmount": число,
  "currency": "UZS",
  "store": "название магазина или null",
  "date": "YYYY-MM-DD или null"
}
Правила:
1. "items" — список купленных товаров.
2. "totalAmount" — итоговая сумма чека (ОБЯЗАТЕЛЬНО).
3. "currency" — валюта (по умолчанию UZS, если не указано иное).
4. Суммы должны быть числами без пробелов.
5. Если текст неразборчив, верни пустой список items, но постарайся найти totalAmount.
6. Отвечай ТОЛЬКО чистым JSON.`,
              },
              {
                type: "image_url",
                image_url: { url: dataUrl },
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
      console.error(`${model} error:`, responseText)
      return NextResponse.json({ error: `${model} error: ${res.status} ${responseText.slice(0, 200)}` }, { status: 500 })
    }

    const data = JSON.parse(responseText)
    const content = data.choices?.[0]?.message?.content ?? "{}"
    
    // Sometimes models wrap JSON in markdown blocks
    const jsonMatch = content.match(/\{[\s\S]*\}/)
    const cleanJson = jsonMatch ? jsonMatch[0] : content
    
    const parsed = JSON.parse(cleanJson)

    // Fallback: calculate total if missing but items present
    if ((!parsed.totalAmount || isNaN(parsed.totalAmount)) && parsed.items?.length > 0) {
      parsed.totalAmount = parsed.items.reduce((s: number, i: any) => s + (i.price || 0), 0)
    }

    return NextResponse.json(parsed)
  } catch (e) {
    console.error("scan-receipt error:", e)
    return NextResponse.json({ error: String(e) }, { status: 500 })
  }
}
