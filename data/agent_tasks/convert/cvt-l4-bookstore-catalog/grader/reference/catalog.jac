"""Bookstore catalog store: what MongoDBConnector.on_parse did against Beanie,
as a graph. Authors hang off root, each Book hangs off its Author via `Wrote`
(the Mongo `author_id` reference becomes the edge). Embeddings are dropped."""

import datetime;

node Author {
    has name: str;
    has created_at: str = "";
}

node Book {
    has title: str;
    has url: str;
    has created_at: str = "";
    has description: str | None = None;
    has language: str | None = None;
    has publisher: str | None = None;
    has publish_year: int | None = None;
    has genre: str | None = None;
    has number_of_pages: int | None = None;
    has isbn: str | None = None;
    has price: float | None = None;
}

edge Wrote: Author --> Book {}

def now_iso -> str {
    return datetime.datetime.utcnow().isoformat();
}

def find_author(name: str) -> Author | None {
    for a in [root -->[?:Author]] {
        if a.name == name {
            return a;
        }
    }
    return None;
}

def find_book(url: str) -> Book | None {
    for a in [root -->[?:Author]] {
        for b in [a ->:Wrote:->] {
            if b.url == url {
                return b;
            }
        }
    }
    return None;
}

def author_of(b: Book) -> Author {
    return [b <-:Wrote:<-][0];
}

def book_view(b: Book) -> dict[str, any] {
    return {"id": jid(b), "title": b.title, "url": b.url, "author": author_of(b).name,
            "description": b.description, "language": b.language, "publisher": b.publisher,
            "publish_year": b.publish_year, "genre": b.genre, "number_of_pages": b.number_of_pages,
            "isbn": b.isbn, "price": b.price};
}

"""on_parse: upsert the author by name, then upsert the book by url."""
walker save_book {
    has url: str;
    has book_title: str | None = None;
    has author_name: str | None = None;
    has description: str | None = None;
    has language: str | None = None;
    has publisher: str | None = None;
    has publish_year: int | None = None;
    has genre: str | None = None;
    has number_of_pages: int | None = None;
    has isbn: str | None = None;
    has price: float | None = None;
    has count_in_complect: int | None = None;

    can upsert with Root entry {
        if (self.count_in_complect or 1) > 1 {
            report {"saved": False, "reason": "complect"};
            return;
        }
        if not self.author_name {
            report {"saved": False, "reason": "no author"};
            return;
        }
        author = find_author(self.author_name);
        if author is None {
            author = Author(name=self.author_name, created_at=now_iso());
            here ++> author;
        }
        book = find_book(self.url);
        created = book is None;
        if book is None {
            book = Book(title=self.book_title or "", url=self.url, created_at=now_iso());
            author +>:Wrote:+> book;
        } else {
            old = author_of(book);
            if old != author {
                del [edge old ->:Wrote:-> book];
                author +>:Wrote:+> book;
            }
            book.title = self.book_title or "";
        }
        book.description = self.description;
        book.language = self.language;
        book.publisher = self.publisher;
        book.publish_year = self.publish_year;
        book.genre = self.genre;
        book.number_of_pages = self.number_of_pages;
        book.isbn = self.isbn;
        book.price = self.price;
        report {"saved": True, "created": created, "author_id": jid(author), "book_id": jid(book)};
    }
}

walker get_book {
    has url: str;

    can fetch with Root entry {
        b = find_book(self.url);
        report book_view(b) if b else None;
    }
}

walker books_by_author {
    has author_name: str;

    can list_books with Root entry {
        a = find_author(self.author_name);
        report [b.title for b in [a ->:Wrote:->]] if a else [];
    }
}

walker list_authors {
    can list_all with Root entry {
        report [a.name for a in [-->[?:Author]]];
    }
}
