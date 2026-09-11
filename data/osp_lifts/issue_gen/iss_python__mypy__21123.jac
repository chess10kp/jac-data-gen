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
