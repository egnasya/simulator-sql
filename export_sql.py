
import json
import re
from pathlib import Path

source = Path("all_queries.json")

folders = {
    "simple": Path("просто_задачи"),
    "product": Path("продуктовые_задачи"),
}

for folder in folders.values():
    folder.mkdir(parents=True, exist_ok=True)

data = json.loads(source.read_text(encoding="utf-8"))

if isinstance(data, dict):
    queries = data.get("results", [])
else:
    queries = data

product_keywords = [
    "retention",
    "churn",
    "конверсия",
    "воронка",
    "когорт",
    "cohort",
    "product",
    "продукт",
    "lifetime",
    "ltv",
    "unit economics",
    "активность пользователей",
    "повторные заказы",
    "средний чек",
    "конверсия",
    "метрики",
    "удержание",
]

for query in queries:
    sql = query.get("query", "")
    query_id = query.get("id", "unknown")
    title = query.get("name") or f"query_{query_id}"

    if not sql.strip():
        continue

    text_to_check = f"{title} {query.get('description', '')}".lower()

    is_product = any(
        keyword in text_to_check
        for keyword in product_keywords
    )

    folder = (
        folders["product"]
        if is_product
        else folders["simple"]
    )

    safe_name = re.sub(r"[^\w.-]+", "_", title).strip("._")
    filename = f"{query_id}_{safe_name or 'query'}.sql"

    content = (
        f"-- Redash query ID: {query_id}\n"
        f"-- Name: {title}\n\n"
        f"{sql.rstrip()}\n"
    )

    (folder / filename).write_text(
        content,
        encoding="utf-8",
    )

print("Экспорт завершён!")
print("обычные задачи:", folders["simple"])
print("продуктовые задачи:", folders["product"])