"""Guard for rec_27_config_include_detach -- candidate OSP lift inlined
verbatim (same-prefix sibling imports are unreliable across jac's native
seam), plus behavioral tests: shared base detached not destroyed,
exclusive chain removed with snapshots, stale/unknown include tolerance.
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
    def include(name: str, base_name: str) -> bool {
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

test "shared_base_detached_not_destroyed" {
    store = load_graph(
        spec=[("app", {"debug": "0"}), ("defaults", {"timeout": "30"}),
              ("env_overrides", {"debug": "1"}),
              ("base_limits", {"timeout": "10", "retries": "3"}),
              ("staging", {"host": "stage"})],
        links=[("app", "defaults"), ("app", "env_overrides"),
               ("defaults", "base_limits"), ("staging", "defaults")]
    );
    snaps = store.remove_section("app");
    assert sorted(snaps.keys()) == ["app", "env_overrides"];
    assert "app" not in store.live_sections();
    assert store.included_by_count("defaults") == 1;
    assert "defaults" in store.live_sections();
    assert "base_limits" in store.live_sections();   # spared with boundary
}

test "exclusive_chain_removed_with_snapshot" {
    store = load_graph(
        spec=[("app", {"debug": "0"}), ("defaults", {"timeout": "30"}),
              ("staging", {"host": "stage"})],
        links=[("app", "defaults"), ("staging", "defaults")]
    );
    snaps = store.remove_section("staging");
    assert snaps["staging"] == {"host": "stage", "timeout": "30"};
    assert "staging" not in store.live_sections();
    assert store.resolve("app") == {"debug": "0", "timeout": "30"};
}

test "unknown_and_stale_includes_tolerated" {
    store = load_graph(
        spec=[("a", {}), ("b", {})],
        links=[]
    );
    ok = store.include("a", "ghost");        # dangling include refused
    assert ok is False;
    assert store.remove_section("ghost") == {};
    assert sorted(store.live_sections()) == ["a", "b"];
}
