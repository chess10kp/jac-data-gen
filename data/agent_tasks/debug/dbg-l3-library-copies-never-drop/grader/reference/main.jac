"""Community lending library: Book/Member nodes, Loan edges, walker API + CLI."""

import sys;
import datetime;

node Book {
    has isbn: str;
    has title: str = "";
    has copies: int = 1;
}

node Member {
    has name: str;
}

edge Loan: Member --> Book {
    has due: str;
}

def find_book(isbn: str) -> Book | None {
    for b in [root -->[?:Book]] {
        if b.isbn == isbn {
            return b;
        }
    }
    return None;
}

def available_copies(b: Book) -> int {
    return b.copies - len([edge b <-:Loan:<-]);
}

walker AddBook {
    has isbn: str;
    has title: str;
    has copies: int = 1;

    can add with Root entry {
        b = find_book(self.isbn);
        if b is None {
            report here ++> Book(isbn=self.isbn, title=self.title, copies=self.copies);
        } else {
            b.title = self.title;
            b.copies = self.copies;
            report b;
        }
    }
}

walker Checkout {
    has member: str;
    has isbn: str;
    has date: str;

    can lend with Root entry {
        b = find_book(self.isbn);
        if b is None or available_copies(b) <= 0 {
            report {"ok": False};
            return;
        }
        found = [m for m in [here -->[?:Member]] if m.name == self.member];
        m = found[0] if found else here ++> Member(name=self.member);
        if b in [m ->:Loan:->] {
            report {"ok": False};
            return;
        }
        due = (datetime.date.fromisoformat(self.date) + datetime.timedelta(days=14)).isoformat();
        m +>:Loan(due=due):+> b;
        report {"ok": True, "due": due};
    }
}

walker ReturnBook {
    has member: str;
    has isbn: str;

    can give_back with Root entry {
        for m in [here -->[?:Member]] {
            if m.name == self.member {
                for b in [m ->:Loan:->] {
                    if b.isbn == self.isbn {
                        del [edge m ->:Loan:-> b];
                        report {"ok": True};
                        return;
                    }
                }
            }
        }
        report {"ok": False};
    }
}

walker Available {
    has isbn: str;

    can count with Root entry {
        b = find_book(self.isbn);
        report available_copies(b) if b is not None else 0;
    }
}

walker Overdue {
    has date: str;
    has rows: list[dict[str, str]] = [];

    can start with Root entry {
        visit [here -->[?:Member]];
    }

    can scan with Member entry {
        for b in [here ->:Loan:->] {
            for e in [edge here ->:Loan:-> b] {
                if e.due < self.date {
                    self.rows.append({"member": here.name, "isbn": b.isbn, "due": e.due});
                }
            }
        }
    }

    can finish with exit {
        report sorted(self.rows, key=lambda (r: dict[str, str]) -> tuple[str, str] { return (r["due"], r["member"]); });
    }
}

def run_cli(argv: list[str]) -> int {
    cmd = argv[0] if argv else "";
    if cmd == "add-book" and len(argv) >= 4 {
        root spawn AddBook(isbn=argv[1], copies=int(argv[2]), title=" ".join(argv[3:]));
        print(f"added {argv[1]}");
    } elif cmd == "checkout" and len(argv) == 4 {
        r = (root spawn Checkout(member=argv[1], isbn=argv[2], date=argv[3])).reports[0];
        print(f"due {r['due']}" if r["ok"] else "unavailable");
    } elif cmd == "return" and len(argv) == 3 {
        r = (root spawn ReturnBook(member=argv[1], isbn=argv[2])).reports[0];
        print("returned" if r["ok"] else "no such loan");
    } elif cmd == "available" and len(argv) == 2 {
        print((root spawn Available(isbn=argv[1])).reports[0]);
    } elif cmd == "overdue" and len(argv) == 2 {
        rows = (root spawn Overdue(date=argv[1])).reports[0];
        if not rows {
            print("none overdue");
        }
        for row in rows {
            print(f"{row['member']} {row['isbn']} {row['due']}");
        }
    } else {
        print("usage: add-book ISBN COPIES TITLE.. | checkout M ISBN DATE | return M ISBN | available ISBN | overdue DATE");
        return 2;
    }
    return 0;
}

with entry:__main__ {
    sys.`exit(run_cli(sys.argv[1:]));
}
