# Память проекта Movo

Эта директория содержит файлы для отслеживания задач, проблем и решений проекта.

## Файлы

- `tasks.json` — список выполненных и запланированных задач
- `issues.json` — список выявленных проблем и недостатков
- `decisions.md` — принятые архитектурные и технические решения

## Структура файлов

### tasks.json
```json
{
  "id": number,
  "title": string,
  "description": string,
  "status": "pending" | "in_progress" | "completed",
  "priority": "low" | "medium" | "high",
  "createdAt": string (ISO date),
  "completedAt": string (ISO date) | null,
  "tags": string[]
}
```

### issues.json
```json
{
  "id": number,
  "title": string,
  "description": string,
  "severity": "low" | "medium" | "high",
  "status": "open" | "in_progress" | "resolved",
  "files": string[],
  "tags": string[],
  "createdAt": string (ISO date),
  "resolvedAt": string (ISO date) | null
}
```
