"""Alias expansion lifted to OSP.

Alias names and terminal tokens become Part nodes (an ``is_alias`` flag
separates the two roles); each alias's parts list becomes HasPart edges,
so the recursive substitution walk of the source becomes walker hops
over typed edges. Two cycle policies survive as domain logic: the
unbounded ``expand`` keeps the source's crash -- a path-scoped walk flags
a token repeating on its own substitution path and the façade raises
RecursionError, exactly as unfixed mypy does -- while ``expand_bounded``
is a depth-capped walk whose cap terminates cyclic tables with a partial
parts set plus the truncated flag instead of crashing.
Ref: python/mypy#21123
"""
node Part {
    has tok: str;
    has is_alias: bool;
}
edge HasPart {}  # alias -> one of its parts

glob MAX_EXPANSION_DEPTH: int = 8;

"""Loader handle: token parameters resolve through this lookup map."""
obj AliasTable {
    has parts: dict[str, Part];

    def resolve(tok: str) -> Part | None {
        return self.parts.get(tok);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def load_table(aliases: dict) -> AliasTable {
    at = AliasTable(parts={});
    keys = list(aliases.keys());
    for tok in keys {
        p = Part(tok=str(tok), is_alias=True);
        root ++> p;
        at.parts[str(tok)] = p;
    }
    for tok in keys {
        plist = list(aliases[tok]);
        for part in plist {
            if str(part) not in at.parts {
                t = Part(tok=str(part), is_alias=False);
                root ++> t;
                at.parts[str(part)] = t;
            }
        }
    }
    for tok in keys {
        owner = at.resolve(str(tok));
        if owner is None {
            continue;
        }
        plist = list(aliases[tok]);
        for part in plist {
            child = at.resolve(str(part));
            if child is None {
                continue;
            }
            owner +>:HasPart:+> child;
        }
    }
    return at;
}

walker ExpandWalk {
    # Cycle policy: path-scoped claim set. A token already on the current
    # substitution path is the cyclic-table case (the source raises
    # RecursionError there); a token first seen on another path is a
    # diamond and only dedupes the parts set.
    has parts: set[str] = set();
    has path: set[str] = set();
    has hit_cycle: bool = False;

    can step with Part entry {
        if here.tok in self.path {
            self.hit_cycle = True;
            return;
        }
        if not here.is_alias {
            self.parts.add(here.tok);
            return;
        }
        for p in [here->:HasPart:->] {
            sub = ExpandWalk(parts=self.parts, path=self.path | {here.tok});
            p spawn sub;
            if sub.hit_cycle {
                self.hit_cycle = True;
                return;
            }
        }
    }
}

walker ExpandBounded {
    # Cycle policy: depth cap (the post-fix shape). An alias sitting at
    # the cap records a cut and stops; terminals are always collectable,
    # and cyclic tables terminate with cuts instead of crashing.
    has parts: set[str] = set();
    has cuts: list[str] = [];
    has depth: int = 0;
    has cap: int = 8;

    can step with Part entry {
        if not here.is_alias {
            self.parts.add(here.tok);
        } elif self.depth >= self.cap {
            self.cuts.append(here.tok);
        } else {
            for p in [here->:HasPart:->] {
                p spawn ExpandBounded(parts=self.parts, cuts=self.cuts, depth=self.depth + 1, cap=self.cap);
            }
        }
    }
}

"""Fully expanded terminal parts of ``name``, sorted and deduped."""
def expand(name: str, aliases: dict) -> list[str] {
    at = load_table(aliases);
    start = at.resolve(name);
    if start is None {
        return [name];  # token unknown to the table expands to itself
    }
    w = start spawn ExpandWalk(parts=set(), path=set());
    if w.hit_cycle {
        raise RecursionError("recursive alias expansion");
    }
    return sorted(w.parts);
}

"""Depth-capped expansion: ``{"parts": [...], "truncated": bool}``."""
def expand_bounded(name: str, aliases: dict, max_depth: int = MAX_EXPANSION_DEPTH) -> dict {
    at = load_table(aliases);
    start = at.resolve(name);
    if start is None {
        return {"parts": [name], "truncated": False};
    }
    w = start spawn ExpandBounded(parts=set(), cuts=[], depth=0, cap=max_depth);
    return {"parts": sorted(w.parts), "truncated": len(w.cuts) > 0};
}


test "simple table expands to sorted terminals" {
    T = {"A": ["int", "B"], "B": ["str"]};
    assert expand("A", T) == ["int", "str"];
    assert expand("B", T) == ["str"];
    assert expand_bounded("A", T) == {"parts": ["int", "str"], "truncated": False};
}

test "diamond dedupes shared terminals" {
    D = {"A": ["B", "C"], "B": ["T"], "C": ["B", "T"]};
    assert expand("A", D) == ["T"];
    assert expand_bounded("A", D, max_depth=4) == {"parts": ["T"], "truncated": False};
}

test "terminal root and unknown names expand to themselves" {
    T = {"A": ["int", "B"], "B": ["str"]};
    assert expand("int", T) == ["int"];
    assert expand("ghost", {}) == ["ghost"];
    assert expand_bounded("ghost", {}, 3) == {"parts": ["ghost"], "truncated": False};
}

test "deep chain full vs depth-capped" {
    chain = {};
    for i in range(10) {
        chain[f"c{i}"] = [f"c{i+1}"];
    }
    assert expand("c0", chain) == ["c10"];
    assert expand_bounded("c0", chain, max_depth=10) == {"parts": ["c10"], "truncated": False};
    assert expand_bounded("c0", chain, max_depth=9) == {"parts": [], "truncated": True};
    assert expand_bounded("c0", chain, max_depth=5) == {"parts": [], "truncated": True};
}

test "cyclic table still raises RecursionError from expand" {
    C = {"A": ["B"], "B": ["A"]};
    try {
        expand("A", C);
        assert False, "expected RecursionError";
    } except RecursionError { assert True; }
    try {
        expand("S", {"S": ["S"]});
        assert False, "expected RecursionError";
    } except RecursionError { assert True; }
}

test "cyclic table terminates under the bounded walk" {
    C = {"A": ["B"], "B": ["A"]};
    assert expand_bounded("A", C) == {"parts": [], "truncated": True};
    assert expand_bounded("S", {"S": ["S"]}) == {"parts": [], "truncated": True};

    E = {"A": ["B", "int"], "B": ["A"]};
    try {
        expand("A", E);
        assert False, "expected RecursionError";
    } except RecursionError { assert True; }
    assert expand_bounded("A", E) == {"parts": ["int"], "truncated": True};
}
