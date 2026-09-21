"""Library catalog: model books as nodes with typed fields and defaults.

Demonstrates `has` defaults (year 0, available True) plus a librarian
walker that sweeps the shelf announcing each book's IN/OUT status.
"""

node Book {
    has title: str = "";
    has year: int = 0;
    has available: bool = True;
}

walker Librarian {
    has shelf_label: str = "Main";

    can start with Root entry {
        print(f"Shelving books for {self.shelf_label} shelf");
        visit [-->];
    }

    can shelve with Book entry {
        status = "IN" if here.available else "OUT";
        print(f"[{status}] {here.title} ({here.year})");
        visit [-->];
    }
}

with entry {
    root ++> Book(title="Dune", year=1965)
        ++> Book(title="Neuromancer", year=1984)
        ++> Book(title="Circe", year=2018, available=False);

    root spawn Librarian(shelf_label="Sci-Fi & Fantasy");
}
