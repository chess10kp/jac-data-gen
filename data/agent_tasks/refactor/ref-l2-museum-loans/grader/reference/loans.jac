"""Museum loan register: museums own artworks and lend them out for whole calendar years."""

node Museum {
    has name: str;
}

node Artwork {
    has title: str;
}

edge Owns: Museum --> Artwork {}

edge LoanedTo: Artwork --> Museum {
    has start_year: int;
    has end_year: int;
}

def find_museum(name: str) -> Museum | None {
    wanted = name;
    found = [root -->[?:Museum, name == wanted]];
    return found[0] if found else None;
}

def find_work(museum: Museum, title: str) -> Artwork | None {
    wanted = title;
    found = [museum -->[?:Artwork, title == wanted]];
    return found[0] if found else None;
}

def add_museum(name: str) -> bool {
    if find_museum(name) is not None {
        return False;
    }
    root ++> Museum(name=name);
    return True;
}

def acquire(museum: str, title: str) -> bool {
    m = find_museum(museum);
    if m is None or find_work(m, title) is not None {
        return False;
    }
    m +>:Owns():+> Artwork(title=title);
    return True;
}

def lend(owner: str, title: str, borrower: str, start_year: int, end_year: int) -> bool {
    o = find_museum(owner);
    b = find_museum(borrower);
    if o is None or b is None or owner == borrower or end_year < start_year {
        return False;
    }
    art = find_work(o, title);
    if art is None {
        return False;
    }
    s = start_year;
    e = end_year;
    if [art ->:LoanedTo:start_year <= e, end_year >= s:->] {
        return False;
    }
    art +>:LoanedTo(start_year=start_year, end_year=end_year):+> b;
    return True;
}

def on_display(museum: str, year: int) -> list[str] {
    m = find_museum(museum);
    if m is None {
        return [];
    }
    y = year;
    shown: set[str] = set();
    for art in [m ->:Owns:->] {
        if not [art ->:LoanedTo:start_year <= y, end_year >= y:->] {
            shown.add(art.title);
        }
    }
    for art in [m <-:LoanedTo:start_year <= y, end_year >= y:<-] {
        shown.add(art.title);
    }
    return sorted(shown);
}

def lenders_to(museum: str) -> list[str] {
    m = find_museum(museum);
    if m is None {
        return [];
    }
    names: set[str] = set();
    for art in [m <-:LoanedTo:<-] {
        for owner in [art <-:Owns:<-] {
            names.add(owner.name);
        }
    }
    return sorted(names);
}
