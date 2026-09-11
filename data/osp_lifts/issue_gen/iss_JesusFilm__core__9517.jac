"""JesusFilm/core#9517 — cycle-safe fixpoint language availability (OSP)."""

obj LanguageStore {
    has stamp: int = 0;
}

node Lang {
    has code: str;
    has available: bool = True;
}

edge Requires {}

def _wire(codes: list[str], requires: list[tuple[str, str]]) {
    mp: dict[str, Lang] = {};
    for c in codes {
        if c not in mp {
            lg = Lang(code=c);
            root ++> lg;
            mp[c] = lg;
        }
    }
    for (dst, src) in requires {
        d = mp.get(dst, None);
        s = mp.get(src, None);
        if d is not None and s is not None {
            d +>:Requires:+> s;
        }
    }
}

def _lang(code: str) -> Lang | None {
    for l in [-->][?:Lang] {
        if l.code == code {
            return l;
        }
    }
    return None;
}

def load_languages(codes: list[str], requires: list[tuple[str, str]]) -> LanguageStore {
    _wire(codes, requires);
    return LanguageStore(stamp=1);
}

def recompute_available(store: LanguageStore) -> int {
    _ = store;
    rounds = 0;
    changed = True;
    while changed {
        changed = False;
        rounds += 1;
        for l in sorted([-->][?:Lang], key=lambda x: x.code) {
            if not l.available {
                continue;
            }
            for dep in [l->:Requires:->][?:Lang] {
                if not dep.available {
                    l.available = False;
                    changed = True;
                }
            }
        }
    }
    return rounds;
}

def available_for(store: LanguageStore, code: str) -> bool {
    _ = store;
    l = _lang(code);
    if l is None {
        return False;
    }
    return l.available;
}
