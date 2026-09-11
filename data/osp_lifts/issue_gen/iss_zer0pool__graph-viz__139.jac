"""Bidirectional lineage impact lifted to OSP (zer0pool/graph-viz#139).

The two adjacency dicts die: ``src feeds dst`` becomes one typed ``Feeds``
edge and reachability becomes an ``ImpactWalk`` over it. The source's depth
cap survives as the walker's hop budget, carried down through per-branch
sub-spawns; the revisit policy is the explicit claim-map (skip on a
revisit, never disengage-on) since jac 0.36.1 has no built-in once-only
visitation. All mutable state lives on a per-instance ``LineageGraph``
handle -- every test constructs a fresh instance, no module-level globals.
"""

node Asset {
    has aid: str;
    has kind: str;
}

edge Feeds: Asset --> Asset {}


walker ImpactWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has budget: int = -1;
    has reverse: bool = False;

    can step with Asset entry {
        if here.aid in self.claimed {
            return;  # diamond/cycle revisit: skip silently
        }
        self.claimed[here.aid] = True;
        self.found.append(here.aid);
        if self.budget == 0 {
            return;  # depth cap: include but do not expand
        }
        next_budget = self.budget - 1;
        if self.budget < 0 {
            next_budget = -1;
        }
        if self.reverse {
            for nb in [here <-:Feeds:<-] {
                sub = ImpactWalk(claimed=self.claimed, budget=next_budget,
                                 reverse=True);
                nb spawn sub;
                self.found.extend(sub.found);
            }
        } else {
            for nb in [here ->:Feeds:->] {
                sub = ImpactWalk(claimed=self.claimed, budget=next_budget,
                                 reverse=False);
                nb spawn sub;
                self.found.extend(sub.found);
            }
        }
    }
}


# Per-instance graph handle: registry lookups are domain API; each test
# builds its own LineageGraph so no state leaks between runs.
obj LineageGraph {
    has assets: dict[str, Asset] = {};

    def add_node(aid: str, kind: str) -> None {
        if kind not in ("table", "job") {
            raise ValueError(kind);
        }
        if aid in self.assets {
            raise ValueError("duplicate node");
        }
        n = Asset(aid=aid, kind=kind);
        root ++> n;
        self.assets[aid] = n;
    }

    def add_edge(src: str, dst: str) -> None {
        # src feeds dst; unknown endpoints fail closed like the source tables
        if src not in self.assets or dst not in self.assets {
            raise KeyError(src if src not in self.assets else dst);
        }
        self.assets[src] +>:Feeds:+> self.assets[dst];
    }

    # sorted asset ids reachable from anchor; reverse selects upstream
    def _closure(anchor: str, max_depth: int | None, reverse: bool) -> list[str] {
        start_budget = -1;
        if max_depth is not None {
            start_budget = max_depth;
        }
        w = self.assets[anchor] spawn ImpactWalk(
            budget=start_budget, reverse=reverse
        );
        return sorted(set(w.found));
    }

    # sorted asset ids reachable from anchor in the given direction
    def impact(anchor: str, direction: str = "downstream",
               max_depth: int | None = None) -> list[str] {
        if anchor not in self.assets {
            raise KeyError(anchor);
        }
        if direction == "upstream" {
            return self._closure(anchor, max_depth, True);
        }
        if direction == "downstream" {
            return self._closure(anchor, max_depth, False);
        }
        if direction == "both" {
            ups = set(self._closure(anchor, max_depth, True));
            downs = set(self._closure(anchor, max_depth, False));
            return sorted(ups | downs);
        }
        raise ValueError(direction);
    }

    def impact_by_kind(anchor: str, direction: str = "downstream",
                       max_depth: int | None = None) -> dict {
        grouped: dict = {"table": [], "job": []};
        for nid in self.impact(anchor, direction, max_depth) {
            grouped[self.assets[nid].kind].append(nid);
        }
        return grouped;
    }

    def max_fanout(anchor: str, max_depth: int | None = None) -> int {
        # widest single join: max direct-feeds count over the closure
        widest = 0;
        for nid in self.impact(anchor, "downstream", max_depth) {
            widest = max(widest, len([self.assets[nid] ->:Feeds:->]));
        }
        return widest;
    }
}
