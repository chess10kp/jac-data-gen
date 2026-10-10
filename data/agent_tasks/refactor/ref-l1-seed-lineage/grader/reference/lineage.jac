"""Seed bank lineage: every SeedLot sits on root; regrown lots record their parent lot."""

node SeedLot {
    has accession: str;
    has species: str;
}

edge RegrownAs: SeedLot --> SeedLot {}

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
    p +>:RegrownAs:+> _make(child, p.species);
    return True;
}

def offspring(accession: str) -> list[str] {
    lot = _lot(accession);
    if lot is None {
        return [];
    }
    return sorted([c.accession for c in [lot ->:RegrownAs:->]]);
}

def ancestry(accession: str) -> list[str] {
    chain: list[str] = [];
    lot = _lot(accession);
    while lot is not None {
        parents = [lot <-:RegrownAs:<-];
        lot = parents[0] if parents else None;
        if lot is not None {
            chain.append(lot.accession);
        }
    }
    return chain;
}

def family_size(accession: str) -> int {
    lot = _lot(accession);
    if lot is None {
        return 0;
    }
    return sum([1 + family_size(c.accession) for c in [lot ->:RegrownAs:->]]);
}
