
import json
import os
import re
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


# ============================================================
# НАСТРОЙКИ
# ============================================================

ROOT = Path(__file__).resolve().parent

REDASH_URL = os.environ.get("REDASH_URL", "").rstrip("/")
REDASH_API_KEY = os.environ.get("REDASH_API_KEY", "")

MY_USER_ID = 56987
PRODUCT_TAG = "product"

QUERY_FOLDERS = {
    "simple": ROOT / "sql_practice" / "queries",
    "product": ROOT / "product_analytics" / "queries",
}

DASHBOARDS_FOLDER = ROOT / "product_analytics" / "dashboards"

MANIFESTS = {
    "simple": ROOT / ".redash_simple_manifest.json",
    "product": ROOT / ".redash_product_manifest.json",
    "dashboards": ROOT / ".redash_dashboards_manifest.json",
}


# ============================================================
# REDASH API
# ============================================================


def api_get(endpoint, params=None):
    """GET-запрос к Redash API с диагностикой ответа."""

    url = f"{REDASH_URL}/api/{endpoint.lstrip('/')}"

    if params:
        url += "?" + urllib.parse.urlencode(params)

    request = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Key {REDASH_API_KEY}",
            "Accept": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            body = response.read().decode("utf-8", errors="replace")

            print(f"API endpoint: {endpoint}")
            print(f"HTTP status: {response.status}")
            print(f"Content-Type: {response.headers.get('Content-Type')}")
            print(f"Response URL: {response.geturl()}")

            if not body.strip():
                raise RuntimeError(
                    f"Redash вернул пустой ответ для {endpoint}. "
                    "Проверь URL и доступность API."
                )

            try:
                return json.loads(body)
            except json.JSONDecodeError as error:
                content_type = response.headers.get("Content-Type", "")
                preview = body[:200].replace("\n", " ").replace("\r", " ")

                raise RuntimeError(
                    f"Ответ Redash не является корректным JSON. "
                    f"Content-Type: {content_type}. "
                    f"Начало ответа: {preview!r}. "
                    "Проверь адрес Redash, редиректы и доступ к API."
                ) from error

    except urllib.error.HTTPError as error:
        raise RuntimeError(
            f"Redash API вернул HTTP {error.code} для {endpoint}. "
            "Проверь адрес, API-ключ и права доступа."
        ) from error

    except urllib.error.URLError as error:
        raise RuntimeError(
            f"Не удалось подключиться к Redash: {error.reason}"
        ) from error


def get_all_pages(endpoint):
    """Получает все страницы API, а не только первые 25 записей."""

    items = []
    page = 1

    while True:
        data = api_get(
            endpoint,
            {"page": page, "page_size": 100},
        )

        if isinstance(data, list):
            items.extend(data)
            break

        results = data.get("results", [])
        items.extend(results)

        if not results:
            break

        count = data.get("count")

        if count is not None and len(items) >= count:
            break

        if len(results) < 100:
            break

        page += 1

    return items


# ============================================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# ============================================================

def normalize_tags(tags):
    """Поддерживает теги в виде строк или объектов."""

    result = set()

    for tag in tags or []:
        if isinstance(tag, str):
            result.add(tag.strip().lower())
        elif isinstance(tag, dict) and tag.get("name"):
            result.add(tag["name"].strip().lower())

    return result


def safe_filename(title):
    name = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "_", title)
    name = re.sub(r"\s+", "_", name).strip("._ ")

    return name or "untitled"


def sort_by_id(item):
    try:
        return (0, int(item.get("id")))
    except (TypeError, ValueError):
        return (1, str(item.get("id", "")))


def remove_secrets(value):
    """Не сохраняет API-ключи и токены в JSON-файлах."""

    if isinstance(value, dict):
        return {
            key: remove_secrets(item)
            for key, item in value.items()
            if key.lower() not in {
                "api_key",
                "apikey",
                "access_token",
                "refresh_token",
            }
        }

    if isinstance(value, list):
        return [remove_secrets(item) for item in value]

    return value


def load_manifest(path):
    if not path.exists():
        return {"items": {}}

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        if isinstance(data.get("items"), dict):
            return data
    except (json.JSONDecodeError, OSError):
        pass

    raise RuntimeError(
        f"Не удалось прочитать {path.name}. "
        "Файл не перезаписан, чтобы не потерять нумерацию."
    )


def save_manifest(path, manifest):
    path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


# ============================================================
# СТАБИЛЬНАЯ НУМЕРАЦИЯ И СИНХРОНИЗАЦИЯ ФАЙЛОВ
# ============================================================

def sync_files(items, folder, manifest_path, make_content):
    """
    ID объекта сохраняет свой номер между запусками.
    Удаляет устаревшие файлы, которые отслеживал этот манифест.
    """

    folder.mkdir(parents=True, exist_ok=True)
    manifest = load_manifest(manifest_path)
    records = manifest["items"]

    current_ids = {str(item["id"]) for item in items}

    # Выдаём новые номера только новым объектам.
    used_numbers = [
        record["number"]
        for record in records.values()
        if isinstance(record.get("number"), int)
    ]
    next_number = max(used_numbers, default=0) + 1

    for item in items:
        object_id = str(item["id"])

        if object_id not in records:
            records[object_id] = {
                "number": next_number,
                "filename": None,
            }
            next_number += 1

        record = records[object_id]
        record["active"] = True

        title = str(item.get("name") or f"object_{object_id}")
        filename = (
            f"{record['number']:02d}_"
            f"{safe_filename(title)}"
        )

        if item.get("_file_extension") == "json":
            filename += ".json"
        else:
            filename += ".sql"

        old_filename = record.get("filename")

        # Если название изменилось, номер сохраняется.
        if old_filename and old_filename != filename:
            old_path = folder / old_filename
            if old_path.exists():
                old_path.unlink()

        record["filename"] = filename

        output_path = folder / filename
        output_path.write_text(
            make_content(item),
            encoding="utf-8",
        )

    # Удаляем только файлы, ранее зарегистрированные
    # нашим манифестом, если объект больше не экспортируется.
    for object_id, record in records.items():
        if object_id in current_ids:
            continue

        record["active"] = False
        old_filename = record.get("filename")

        if old_filename:
            old_path = folder / old_filename
            if old_path.exists():
                old_path.unlink()

    save_manifest(manifest_path, manifest)
    print(f"{folder.relative_to(ROOT)}: {len(items)} файлов")


# ============================================================
# ЭКСПОРТ SQL-ЗАПРОСОВ
# ============================================================

def export_queries():
    # Получаем избранные запросы напрямую из Redash.
    favorites = get_all_pages("queries/favorites")

    selected = [
        query for query in favorites
        if not query.get("is_archived", False)
    ]

    groups = {"simple": [], "product": []}

    for query in selected:
        # Если SQL или теги отсутствуют в списке избранного,
        # получаем полное определение запроса по ID.
        if (
            not query.get("query", "").strip()
            or "tags" not in query
        ):
            query = api_get(f"queries/{query['id']}")

        if query.get("is_archived", False):
            continue

        tags = normalize_tags(query.get("tags", []))
        category = "product" if PRODUCT_TAG in tags else "simple"

        if query.get("query", "").strip():
            groups[category].append(query)

    for category, group in groups.items():
        group.sort(key=sort_by_id)

        def make_sql(query):
            title = str(query.get("name") or "")
            sql = query.get("query", "").rstrip()
            query_id = query["id"]

            return (
                f"-- Redash query ID: {query_id}\n"
                f"-- Name: {title}\n\n"
                f"{sql}\n"
            )

        sync_files(
            group,
            QUERY_FOLDERS[category],
            MANIFESTS[category],
            make_sql,
        )

    print(
        f"Избранные SQL-запросы: "
        f"{len(groups['simple']) + len(groups['product'])}; "
        f"обычные: {len(groups['simple'])}; "
        f"product: {len(groups['product'])}"
    )


# ============================================================
# ЭКСПОРТ ПРОДУКТОВЫХ ДАШБОРДОВ
# ============================================================

def export_dashboards():
    # Только дашборды текущего пользователя.
    dashboards = get_all_pages("dashboards/my")

    product_dashboards = []

    for dashboard in dashboards:
        tags = normalize_tags(dashboard.get("tags", []))

        if PRODUCT_TAG not in tags:
            continue

        # Запрашиваем полную конфигурацию дашборда.
        details = api_get(f"dashboards/{dashboard['id']}")

        if not isinstance(details, dict) or not details.get("id"):
            raise RuntimeError(
                f"Не удалось получить дашборд ID {dashboard['id']}."
            )

        details["_file_extension"] = "json"
        product_dashboards.append(details)

    product_dashboards.sort(key=sort_by_id)

    def make_dashboard_json(dashboard):
        # Внутреннее поле используется только для выбора расширения.
        clean = {
            key: value
            for key, value in dashboard.items()
            if key != "_file_extension"
        }

        return (
            json.dumps(
                remove_secrets(clean),
                ensure_ascii=False,
                indent=2,
            )
            + "\n"
        )

    sync_files(
        product_dashboards,
        DASHBOARDS_FOLDER,
        MANIFESTS["dashboards"],
        make_dashboard_json,
    )


# ============================================================
# ЗАПУСК
# ============================================================

def main():
    if not REDASH_URL or not REDASH_API_KEY:
        raise RuntimeError(
            "Сначала задай переменные REDASH_URL и REDASH_API_KEY."
        )

    print("Получаю данные из Redash...")

    # Проверяем подключение до начала экспорта.
    api_get("queries/favorites", {"page": 1, "page_size": 1})

    export_queries()
    export_dashboards()

    print("Синхронизация завершена!")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, urllib.error.URLError) as error:
        raise SystemExit(f"Ошибка: {error}")