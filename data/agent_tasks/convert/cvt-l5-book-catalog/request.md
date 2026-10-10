`python/app/` is a little FastAPI + Beanie demo API for a book catalog (model in `python/app/models/book.py`, routes in `python/app/main.py`). I'd like the same API as a Jac service, data living in the Jac graph instead of Mongo/DocumentDB.

Write `main.jac` (entry point is already configured in `jac.toml`) with a `Book` node and one public walker per route, named like the Python handlers:

- `health()` → `{"status": "healthy", "db": "connected"}`
- `create_book(title, author, genres=[], pages=None, published=None, in_stock=True, rating=None)` → the stored book
- `list_books(author=None)` → `{"count": n, "books": [...]}`, newest first, max 100, filtered by author when given
- `get_book(book_id)`
- `update_book(book_id, ...any book fields)` — only the fields you actually pass change; bump `updated_at` when something changed; returns the book
- `delete_book(book_id)` → `{"deleted": "<book_id>"}`
- `genre_stats()` → list of `{"_id": genre, "count": n}` (what the aggregation pipeline returns), most common genre first, ties by genre name

A book is reported as a dict with `id` (the node's jid), the model fields, and `created_at`/`updated_at` as ISO-8601 UTC strings. Where the Python raises a 404, report `{"error": "not found"}`.

Should start with `jac start main.jac` and be clean under `jac check`.
