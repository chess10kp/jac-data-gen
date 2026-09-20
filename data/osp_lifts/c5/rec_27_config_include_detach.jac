"""Idiomatic OSP lift: config include-tree cascade removal (category C5).

Two-phase mutation protocol (OSP_IDIOMIZE_TASK.md §5.5):

Phase COLLECT -- `IncludeScan` walks `Includes` edges from the requested
section and gathers doomed sections plus their resolved parameter maps
into typed `has` fields. A base still inherited by a surviving section
(`included_by > 1`) is a shared boundary: it is recorded as detached, not
destroyed, and never descended past. The seen-guard is the once-only
diamond guard and the explicit cycle policy; `skip;` preserves siblings.

Phase APPLY -- outside any walk: dying includers release their counts,
doomed sections are disconnected and destroyed, and one registry sweep
drops stale include entries. Kept semantics: unknown names are a silent
no-op; snapshots reflect own-params-win resolution.
"""

node CfgSection {
    has name: str;
    has params: dict[str, str];
    has included_by: int = 0;
}

edge Includes { }

"""Collect doomed exclusive bases below one section."""
walker IncludeScan {
    has root_name: str;
    has doomed: list[CfgSection] = [];
    has seen: dict[str, bool] = {};

    can scan with CfgSection entry {
        if here.name in self.seen {
            skip;           # diamond revisit / cycle policy: decide once,
        }                   # keep sibling branches alive
        self.seen[here.name] = True;
        if here.name != self.root_name and here.included_by > 1 {
            skip;           # shared base: detach later, spare subtree
        }
        self.doomed.append(here);
        visit [->:Includes:->];
    }
}

obj ConfigStore {
    has sections: dict[str, CfgSection];

    def add(name: str, params: dict[str, str]) -> CfgSection {
        fresh = CfgSection(name=name, params=params);
        self.sections[name] = fresh;
        return fresh;
    }

    """Make *name* inherit *base_name*; unknown refs tolerated (refused)."""
    def `include(name: str, base_name: str) -> bool {
        sec = self.sections.get(name);
        base = self.sections.get(base_name);
        if sec is None or base is None {
            return False;
        }
        sec +>:Includes:+> base;
        base.included_by += 1;
        return True;
    }

    """Merge params along includes; own params win. Unknown -> None."""
    def resolve(name: str) -> dict[str, str] | None {
        sec = self.sections.get(name);
        if sec is None {
            return None;
        }
        merged: dict[str, str] = {};
        bases = [sec ->:Includes:->] as list[CfgSection];
        for b in bases {
            base_map = self.resolve(b.name);
            if base_map is not None {
                merged.update(base_map);
            }
        }
        merged.update(sec.params);
        return merged;
    }

    """Remove *name* + exclusive bases; returns removed-name snapshots."""
    def remove_section(name: str) -> dict[str, dict[str, str]] {
        start = self.sections.get(name);
        if start is None {
            return {};
        }
        # Phase COLLECT -- walk the include closure without mutating.
        scan = start spawn IncludeScan(root_name=name);

        # Phase APPLY -- mutation strictly after the walk finished.
        snapshots: dict[str, dict[str, str]] = {};
        for dead in scan.doomed {
            snap: dict[str, str] = {};
            bases = [dead ->:Includes:->] as list[CfgSection];
            for b in bases {
                if b.name != name and b.name in self.sections {
                    snap.update(b.params);
                }
            }
            snap.update(dead.params);
            snapshots[dead.name] = snap;
            kids = [dead ->:Includes:->] as list[CfgSection];
            for b in kids {
                b.included_by -= 1;         # dying inheritor releases hold
                dead del ->:Includes:-> b;
            }
            dead_name = dead.name;  # capture before del unbinds the ref
            del dead;
            _gone = self.sections.pop(dead_name, None);
        }
        # Note: the source's sweeper pass over stale include entries is
        # unnecessary here -- jac purges a deleted node's remaining edges,
        # so dangling `Includes` references cannot survive the dels above.
        return snapshots;
    }

    def live_sections -> list[str] {
        return sorted(self.sections.keys());
    }

    def included_by_count(name: str) -> int | None {
        sec = self.sections.get(name);
        if sec is None {
            return None;
        }
        return sec.included_by;
    }
}

"""Build a fresh deterministic store; creation order = fixture order."""
def load_graph(spec: list[tuple[str, dict[str, str]]],
               links: list[tuple[str, str]]) -> ConfigStore {
    store = ConfigStore(sections={});
    for row in spec {
        _made = store.add(row[0], row[1]);
    }
    for pair in links {
        _ok = store.include(pair[0], pair[1]);
    }
    return store;
}
