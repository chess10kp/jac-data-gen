"""Book rental service as a graph.

BookModel / PersonModel documents -> Book / Person nodes on root. A
BookRentalModel stored `book_id` / `person_id` strings; here a Rental node
hangs off its Person (`Rents`) and points at its Book (`RentalOf`).
Repository + service methods -> walkers; HTTP errors are reported as
{"status": <code>, "detail": <message>}. Timestamps are ISO-8601 strings.
"""

import datetime;

node Book {
    has title: str;
    has description: str;
    has author: str;
    has isbn: str | None = None;
    has genre: str | None = None;
    has available_copies: int = 0;
    has total_copies: int = 0;

    def view -> dict[str, any] {
        return {"id": jid(self), "title": self.title, "description": self.description,
                "isbn": self.isbn, "author": self.author, "genre": self.genre,
                "available_copies": self.available_copies, "total_copies": self.total_copies};
    }
}

node Person {
    has name: str;
    has age: int;
    has email: str;
    has phone: str | None = None;
    has address: str | None = None;

    def view -> dict[str, any] {
        return {"id": jid(self), "name": self.name, "age": self.age, "email": self.email,
                "phone": self.phone, "address": self.address};
    }
}

node Rental {
    has rental_date: str;
    has due_date: str;
    has return_date: str | None = None;
    has status: str = "active";
}

edge Rents: Person --> Rental {}
edge RentalOf: Rental --> Book {}

def now_iso -> str {
    return datetime.datetime.now().isoformat();
}

def err(code: int, detail: str) -> dict[str, any] {
    return {"status": code, "detail": detail};
}

def find_book(book_id: str) -> Book | None {
    for b in [root -->[?:Book]] {
        if jid(b) == book_id {
            return b;
        }
    }
    return None;
}

def find_person(person_id: str) -> Person | None {
    for p in [root -->[?:Person]] {
        if jid(p) == person_id {
            return p;
        }
    }
    return None;
}

def all_rentals -> list[Rental] {
    return [r for p in [root -->[?:Person]] for r in [p ->:Rents:->]];
}

def find_rental(rental_id: str) -> Rental | None {
    for r in all_rentals() {
        if jid(r) == rental_id {
            return r;
        }
    }
    return None;
}

def rental_book(r: Rental) -> Book {
    return [r ->:RentalOf:->][0];
}

def rental_person(r: Rental) -> Person {
    return [r <-:Rents:<-][0];
}

def rental_view(r: Rental) -> dict[str, any] {
    return {"id": jid(r), "book_id": jid(rental_book(r)), "person_id": jid(rental_person(r)),
            "rental_date": r.rental_date, "due_date": r.due_date, "return_date": r.return_date,
            "status": r.status};
}

"""BookRepository.update_available_copies: refuses to go below zero."""
def update_available_copies(b: Book, change: int) -> bool {
    if b.available_copies + change < 0 {
        return False;
    }
    b.available_copies += change;
    return True;
}

# ---------------------------------------------------------------- books
walker create_book {
    has title: str;
    has description: str;
    has author: str;
    has isbn: str | None = None;
    has genre: str | None = None;
    has available_copies: int = 0;
    has total_copies: int = 0;

    can create with Root entry {
        if self.available_copies < 0 or self.total_copies < 0 {
            report err(422, "Copies must be non-negative");
            return;
        }
        if self.available_copies > self.total_copies {
            report err(422, "Available copies cannot exceed total copies");
            return;
        }
        b = here ++> Book(title=self.title, description=self.description, author=self.author,
                          isbn=self.isbn, genre=self.genre, available_copies=self.available_copies,
                          total_copies=self.total_copies);
        report b.view();
    }
}

walker get_book {
    has book_id: str;

    can fetch with Root entry {
        b = find_book(self.book_id);
        report b.view() if b else err(404, f"Book with ID {self.book_id} not found");
    }
}

walker get_available_books {
    can list_free with Root entry {
        report [b.view() for b in [-->[?:Book]] if b.available_copies > 0];
    }
}

walker check_availability {
    has book_id: str;

    can check with Root entry {
        b = find_book(self.book_id);
        report b is not None and b.available_copies > 0;
    }
}

# ---------------------------------------------------------------- people
walker create_person {
    has name: str;
    has age: int;
    has email: str;
    has phone: str | None = None;
    has address: str | None = None;

    can create with Root entry {
        p = here ++> Person(name=self.name, age=self.age, email=self.email, phone=self.phone, address=self.address);
        report p.view();
    }
}

walker get_person {
    has person_id: str;

    can fetch with Root entry {
        p = find_person(self.person_id);
        report p.view() if p else err(404, f"Person with ID {self.person_id} not found");
    }
}

# ---------------------------------------------------------------- rentals
walker create_rental {
    has book_id: str;
    has person_id: str;
    has due_date: str;

    can rent with Root entry {
        b = find_book(self.book_id);
        if b is None {
            report err(404, f"Book with ID {self.book_id} not found");
            return;
        }
        if b.available_copies <= 0 {
            report err(409, f"Book '{b.title}' is not available for rental");
            return;
        }
        p = find_person(self.person_id);
        if p is None {
            report err(404, f"Person with ID {self.person_id} not found");
            return;
        }
        r = Rental(rental_date=now_iso(), due_date=self.due_date);
        p +>:Rents:+> r;
        r +>:RentalOf:+> b;
        update_available_copies(b, -1);
        report rental_view(r);
    }
}

walker get_rental {
    has rental_id: str;

    can fetch with Root entry {
        r = find_rental(self.rental_id);
        if r is None {
            report err(404, f"Rental with ID {self.rental_id} not found");
            return;
        }
        detail = rental_view(r);
        b = rental_book(r);
        p = rental_person(r);
        detail["book_title"] = b.title;
        detail["person_name"] = p.name;
        detail["person_email"] = p.email;
        report detail;
    }
}

walker get_all_rentals {
    has `skip: int = 0;
    has limit: int = 100;

    can list_all with Root entry {
        report [rental_view(r) for r in all_rentals()[self.skip:self.skip + self.limit]];
    }
}

walker return_book {
    has rental_id: str;

    can give_back with Root entry {
        r = find_rental(self.rental_id);
        if r is None {
            report err(404, f"Rental with ID {self.rental_id} not found");
            return;
        }
        r.return_date = now_iso();
        r.status = "returned";
        update_available_copies(rental_book(r), 1);
        report rental_view(r);
    }
}

"""check_and_send_notifications: active rentals due before `now` become
overdue; the queued notification messages are reported instead of published."""
walker check_overdue {
    has now: str;

    can sweep with Root entry {
        messages: list[dict[str, any]] = [];
        for r in all_rentals() {
            if r.status == "active" and r.due_date < self.now {
                b = rental_book(r);
                p = rental_person(r);
                messages.append({"type": "overdue", "rental_id": jid(r), "book_title": b.title,
                                 "person_name": p.name, "person_email": p.email,
                                 "due_date": r.due_date, "rental_date": r.rental_date});
                r.status = "overdue";
            }
        }
        report messages;
    }
}
