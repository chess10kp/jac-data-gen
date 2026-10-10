"""Museum loan register: museums own artworks and lend them out for whole calendar years."""

node Register {
    has museums: dict[str, dict[str, any]] = {};
}

def _register() -> Register {
    for n in [root -->] {
        if isinstance(n, Register) {
            return n;
        }
    }
    r = Register();
    root ++> r;
    return r;
}

def add_museum(name: str) -> bool {
    reg = _register();
    if name in reg.museums {
        return False;
    }
    reg.museums[name] = {"works": {}};
    return True;
}

def acquire(museum: str, title: str) -> bool {
    reg = _register();
    if museum not in reg.museums {
        return False;
    }
    works = reg.museums[museum]["works"];
    if title in works {
        return False;
    }
    works[title] = [];
    return True;
}

def lend(owner: str, title: str, borrower: str, start_year: int, end_year: int) -> bool {
    reg = _register();
    if owner not in reg.museums or borrower not in reg.museums or owner == borrower {
        return False;
    }
    works = reg.museums[owner]["works"];
    if title not in works or end_year < start_year {
        return False;
    }
    for loan in works[title] {
        if loan["start"] <= end_year and loan["end"] >= start_year {
            return False;
        }
    }
    works[title].append({"to": borrower, "start": start_year, "end": end_year});
    return True;
}

def on_display(museum: str, year: int) -> list[str] {
    reg = _register();
    if museum not in reg.museums {
        return [];
    }
    shown: list[str] = [];
    works = reg.museums[museum]["works"];
    for title in works {
        away = False;
        for loan in works[title] {
            if loan["start"] <= year and loan["end"] >= year {
                away = True;
            }
        }
        if not away and title not in shown {
            shown.append(title);
        }
    }
    for other in reg.museums {
        others = reg.museums[other]["works"];
        for title in others {
            for loan in others[title] {
                if loan["to"] == museum and loan["start"] <= year and loan["end"] >= year and title not in shown {
                    shown.append(title);
                }
            }
        }
    }
    return sorted(shown);
}

def lenders_to(museum: str) -> list[str] {
    reg = _register();
    if museum not in reg.museums {
        return [];
    }
    out: list[str] = [];
    for other in reg.museums {
        others = reg.museums[other]["works"];
        for title in others {
            for loan in others[title] {
                if loan["to"] == museum and other not in out {
                    out.append(other);
                }
            }
        }
    }
    return sorted(out);
}
