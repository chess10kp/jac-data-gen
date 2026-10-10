"""Book catalog API (port of documentdb/documentdb-playground, Beanie demo app).

Beanie `Book` document -> `Book` node on root; FastAPI routes -> public walkers
named after the handlers; Mongo `_id` -> the node's jid; HTTPException(404) ->
reported {"error": "not found"}; the genre aggregation pipeline -> a plain
fold over the graph.
"""
import from datetime { datetime, timezone }

def utcnow -> str {
    return datetime.now(timezone.utc).isoformat();
}

node Book {
    has title: str;
    has author: str;
    has genres: list[str] = [];
    has pages: int | None = None;
    has published: str | None = None;
    has in_stock: bool = True;
    has rating: float | None = None;
    has created_at: str = "";
    has updated_at: str = "";

    def view -> dict[str, any] {
        return {"id": jid(self), "title": self.title, "author": self.author,
                "genres": list(self.genres), "pages": self.pages, "published": self.published,
                "in_stock": self.in_stock, "rating": self.rating,
                "created_at": self.created_at, "updated_at": self.updated_at};
    }
}

def find_book(book_id: str) -> Book | None {
    for b in [root -->[?:Book]] {
        if jid(b) == book_id {
            return b;
        }
    }
    return None;
}

"""GET /health"""
walker:pub health {
    can ping with Root entry {
        report {"status": "healthy", "db": "connected"};
    }
}

"""POST /books"""
walker:pub create_book {
    has title: str;
    has author: str;
    has genres: list[str] = [];
    has pages: int | None = None;
    has published: str | None = None;
    has in_stock: bool = True;
    has rating: float | None = None;

    can create with Root entry {
        now = utcnow();
        b = here ++> Book(title=self.title, author=self.author, genres=self.genres, pages=self.pages,
                          published=self.published, in_stock=self.in_stock, rating=self.rating,
                          created_at=now, updated_at=now);
        report b.view();
    }
}

"""GET /books?author= -- newest first, at most 100."""
walker:pub list_books {
    has author: str | None = None;

    can list_all with Root entry {
        books = [b for b in [here -->[?:Book]] if not self.author or b.author == self.author];
        books.reverse();
        books = sorted(books, key=lambda (b: Book) -> str { return b.created_at; }, reverse=True)[:100];
        report {"count": len(books), "books": [b.view() for b in books]};
    }
}

"""GET /books/{book_id}"""
walker:pub get_book {
    has book_id: str;

    can fetch with Root entry {
        b = find_book(self.book_id);
        report b.view() if b else {"error": "not found"};
    }
}

"""PATCH /books/{book_id} -- only the fields that are given change."""
walker:pub update_book {
    has book_id: str;
    has title: str | None = None;
    has author: str | None = None;
    has genres: list[str] | None = None;
    has pages: int | None = None;
    has published: str | None = None;
    has in_stock: bool | None = None;
    has rating: float | None = None;

    can patch with Root entry {
        b = find_book(self.book_id);
        if b is None {
            report {"error": "not found"};
            return;
        }
        changed = False;
        if self.title is not None { b.title = self.title; changed = True; }
        if self.author is not None { b.author = self.author; changed = True; }
        if self.genres is not None { b.genres = self.genres; changed = True; }
        if self.pages is not None { b.pages = self.pages; changed = True; }
        if self.published is not None { b.published = self.published; changed = True; }
        if self.in_stock is not None { b.in_stock = self.in_stock; changed = True; }
        if self.rating is not None { b.rating = self.rating; changed = True; }
        if changed {
            b.updated_at = utcnow();
        }
        report b.view();
    }
}

"""DELETE /books/{book_id}"""
walker:pub delete_book {
    has book_id: str;

    can remove with Root entry {
        b = find_book(self.book_id);
        if b is None {
            report {"error": "not found"};
            return;
        }
        del b;
        report {"deleted": self.book_id};
    }
}

"""GET /stats/genres -- books per genre, most common first (ties by name)."""
walker:pub genre_stats {
    can count with Root entry {
        counts: dict[str, int] = {};
        for b in [here -->[?:Book]] {
            for g in b.genres {
                counts[g] = counts.get(g, 0) + 1;
            }
        }
        ordered = sorted(counts.items(), key=lambda (kv: tuple[str, int]) -> tuple[int, str] { return (-kv[1], kv[0]); });
        report [{"_id": g, "count": n} for (g, n) in ordered];
    }
}
