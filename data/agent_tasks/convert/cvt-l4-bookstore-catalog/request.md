The scraper in `python/` saves parsed bookstore pages into Mongo through `MongoDBConnector.on_parse` (`python/connectors/mongodb_connector.py`, models in `python/db/mongodb/models/`). I want that storage layer in Jac, as a graph, in `catalog.jac`. Don't bother with the OpenAI embeddings.

Model: `Author` nodes on `root` (`name`, `created_at`), and `Book` nodes connected from their author with a `Wrote` edge (that replaces `author_id`). Keep these book fields: `title`, `url`, `created_at`, `description`, `language`, `publisher`, `publish_year`, `genre`, `number_of_pages`, `isbn`, `price` (all but title/url/created_at optional).

Walkers, spawned on `root`:

- `save_book(url, book_title=None, author_name=None, description=None, language=None, publisher=None, publish_year=None, genre=None, number_of_pages=None, isbn=None, price=None, count_in_complect=None)` — this is `on_parse`:
  - books that are part of a set (`count_in_complect > 1`) are skipped → report `{"saved": False, "reason": ...}`; same if there's no author name;
  - find the author by name or create it;
  - find the book by `url`: if it exists, refresh all its fields from the input (it may now belong to a different author — move it), otherwise create it under the author;
  - report `{"saved": True, "created": <bool>, "author_id": <jid>, "book_id": <jid>}`.
- `get_book(url)` → dict with `id`, `author` (the author's name) and the book fields above except `created_at`, or `None`.
- `books_by_author(author_name)` → list of titles (empty list if unknown).
- `list_authors()` → list of author names.

`jac check` should pass.
