"""lrburkholder/battalion#74 — BTN-98 Cartography logical data contract (OSP)."""

obj Cartography {
    has stamp: int = 0;
}

node Field {
    has name: str;
}

edge DerivesFrom {}

walker LineageWalk {
    has start: str;
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can begin with Root entry {
        for f in [-->][?:Field] {
            if f.name == self.start {
                visit [f];
            }
        }
    }

    can step with Field entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        if here.name != self.start {
            self.reached.append(here.name);
        }
        visit [here->:DerivesFrom:->][?:Field];
    }

    can finish with Root exit {
        report self.reached;
    }
}

def _wire(fields: list[str], derives: list[tuple[str, str]]) {
    mp: dict[str, Field] = {};
    for nm in fields {
        if nm not in mp {
            f = Field(name=nm);
            root ++> f;
            mp[nm] = f;
        }
    }
    for (child, parent) in derives {
        c = mp.get(child, None);
        p = mp.get(parent, None);
        if c is not None and p is not None {
            dup = False;
            for up in [c ->:DerivesFrom:->][?:Field] {
                if up.name == parent {
                    dup = True;
                }
            }
            if not dup {
                c +>:DerivesFrom:+> p;
            }
        }
    }
}

def _field(name: str) -> Field | None {
    for f in [-->][?:Field] {
        if f.name == name {
            return f;
        }
    }
    return None;
}

def load_cartography(
    fields: list[str],
    derives: list[tuple[str, str]],
) -> Cartography {
    _wire(fields, derives);
    return Cartography(stamp=1);
}

def lineage_closure(c: Cartography, field: str) -> list[str] {
    _ = c;
    if _field(field) is None {
        return [];
    }
    w = root spawn LineageWalk(start=field, claimed={}, reached=[]);
    return sorted(w.reports[0] if w.reports else []);
}

def canonical_fields(c: Cartography) -> list[str] | None {
    _ = c;
    indeg: dict[str, int] = {};
    for f in [-->][?:Field] {
        indeg[f.name] = len([f ->:DerivesFrom:->][?:Field]);
    }
    out: list[str] = [];
    ready = sorted([nm for (nm, d) in indeg.items() if d == 0]);
    while ready {
        out += ready;
        nxt: list[str] = [];
        for nm in ready {
            cur = _field(nm);
            if cur is None {
                continue;
            }
            for dep in [cur <-:DerivesFrom:<-][?:Field] {
                indeg[dep.name] -= 1;
                if indeg[dep.name] == 0 {
                    nxt.append(dep.name);
                }
            }
        }
        ready = sorted(nxt);
    }
    return out if len(out) == len(indeg) else None;
}
