"""Scene graph transforms lifted to OSP (paulgessinger/nodehammer#43).

The id-keyed node table and its per-visit whole-table child rescans die:
hierarchy links become two typed edges -- ``SceneChild`` (parent --> child)
and its inverse ``SceneParent`` (child --> parent) -- so every walk is a
plain forward hop over a typed edge. Ascent is the linear ``AncestorWalk``
whose claim-map is the cycle policy (the issue's hardened contract: a
controlled ``ValueError`` on a parent loop instead of a hang), and
reachability is a claiming walk that terminates with a finite set even on
cycles.
"""

node SNode {
    has sid: str;
    has local: float = 1.0;
}

edge SceneChild: SNode --> SNode {}

edge SceneParent: SNode --> SNode {}

glob scene: dict[str, SNode] = {};


def _link(parent: str, child: str) -> None {
    # both directions are maintained together by the facade mutators
    scene[parent] +>:SceneChild:+> scene[child];
    scene[child] +>:SceneParent:+> scene[parent];
}


def _unlink(parent: str, child: str) -> None {
    scene[parent] del ->:SceneChild:-> scene[child];
    scene[child] del ->:SceneParent:-> scene[parent];
}


def add_node(nid: str, parent: str | None = None, local: float = 1.0) -> None {
    if nid in scene {
        raise ValueError("duplicate node");
    }
    root ++> (n := SNode(sid=nid, local=local));
    scene[nid] = n;
    if parent is not None {
        if parent not in scene {
            raise KeyError(parent);
        }
        _link(parent, nid);
    }
}


def children(nid: str) -> list[str] {
    out: set[str] = set();
    for c in [scene[nid] ->:SceneChild:->] {
        out.add(c.sid);
    }
    return sorted(out);
}


walker AncestorWalk {
    """Linear climb to the root; flags a corrupt loop."""
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];
    has hit_cycle: bool = False;

    can climb with SNode entry {
        if here.sid in self.claimed {
            self.hit_cycle = True;
            return;
        }
        self.claimed[here.sid] = True;
        self.chain.append(here.sid);
        visit [->:SceneParent:->] else { disengage; }
    }
}


def ancestors(nid: str) -> list[str] {
    if nid not in scene {
        raise KeyError(nid);
    }
    w = scene[nid] spawn AncestorWalk(claimed={});
    if w.hit_cycle {
        raise ValueError("parent cycle");
    }
    return w.chain[1:];  # exclude start node
}


walker ReachWalk {
    """Descendant closure; revisits are skipped, never disengaged on."""
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can go with SNode entry {
        if here.sid in self.claimed {
            return;
        }
        self.claimed[here.sid] = True;
        self.found.append(here.sid);
        for ch in [here ->:SceneChild:->] {
            sub = ReachWalk(claimed=self.claimed);
            ch spawn sub;
            self.found.extend(sub.found);
        }
    }
}


def reachable(start: str) -> list[str] {
    if start not in scene {
        raise KeyError(start);
    }
    w = scene[start] spawn ReachWalk(claimed={});
    return sorted(set(w.found));
}


def world_transform(nid: str) -> float {
    # product of locals along root -> nid, inclusive
    prod = 1.0;
    chain = ancestors(nid);
    i = len(chain);
    while i > 0 {
        i -= 1;
        prod *= scene[chain[i]].local;
    }
    return round(prod * scene[nid].local, 6);
}


def compute_world_transforms() -> dict {
    out: dict = {};
    for nid in sorted(scene.keys()) {
        out[nid] = world_transform(nid);
    }
    return out;
}


def validate_acyclic() -> bool {
    for nid in sorted(scene.keys()) {
        ancestors(nid);  # raises on any parent loop
    }
    return True;
}
