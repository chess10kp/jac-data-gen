"""Seed bank lineage: every SeedLot sits on root; regrown lots record their parent lot."""

node SeedLot {
    has accession: str;
    has species: str;
    has regrown_into: list[str] = [];
}

def _lot(accession: str) -> SeedLot | None {
    wanted = accession;
    found = [root -->[?:SeedLot, accession == wanted]];
    return found[0] if found else None;
}

def _make(accession: str, species: str) -> SeedLot {
    lot = SeedLot(accession=accession, species=species);
    root ++> lot;
    return lot;
}

def bank_lot(accession: str, species: str) -> bool {
    if _lot(accession) is not None {
        return False;
    }
    _make(accession, species);
    return True;
}

def regrow(parent: str, child: str) -> bool {
    p = _lot(parent);
    if p is None or _lot(child) is not None {
        return False;
    }
    _make(child, p.species);
    p.regrown_into.append(child);
    return True;
}

def offspring(accession: str) -> list[str] {
    lot = _lot(accession);
    return sorted(lot.regrown_into) if lot is not None else [];
}

def ancestry(accession: str) -> list[str] {
    chain: list[str] = [];
    current = accession;
    searching = True;
    while searching {
        searching = False;
        for lot in [root -->[?:SeedLot]] {
            if current in lot.regrown_into {
                chain.append(lot.accession);
                current = lot.accession;
                searching = True;
                break;
            }
        }
    }
    return chain;
}

def family_size(accession: str) -> int {
    lot = _lot(accession);
    if lot is None {
        return 0;
    }
    total = 0;
    for name in lot.regrown_into {
        total += 1 + family_size(name);
    }
    return total;
}
