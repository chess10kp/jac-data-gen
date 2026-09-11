"""JS-value conversion lifted to OSP (hmsk/quickjs.rb#90).

Values become ``VNode`` nodes and object properties become typed ``Prop``
edges carrying their key as an edge payload. The converter's ancestor-path
bookkeeping -- the exact machinery the issue's regression got wrong by using
one global visited set -- becomes a claim-map threaded down through
per-branch sub-spawns: each branch carries only its own root-to-node
ancestor path, so shared non-cyclic references materialize under every
parent while genuine cycles are flagged and re-raised by the facade.
"""

node VNode {
    has vid: str;
    has kind: str;   # "obj" | "scalar"
    has sval: str;
}

edge Prop: VNode --> VNode {
    has key: str;
}

glob vals: dict[str, VNode] = {};


def add_object(vid: str) -> None {
    if vid in vals {
        raise ValueError("duplicate vid");
    }
    root ++> (n := VNode(vid=vid, kind="obj", sval=""));
    vals[vid] = n;
}


def add_scalar(vid: str, val: str) -> None {
    if vid in vals {
        raise ValueError("duplicate vid");
    }
    root ++> (n := VNode(vid=vid, kind="scalar", sval=val));
    vals[vid] = n;
}


def add_prop(pid: str, key: str, cid: str) -> None {
    # attach child cid under key on object pid
    if pid not in vals or cid not in vals {
        raise KeyError(pid);
    }
    vals[pid] +>:Prop(key=key):+> vals[cid];
}


walker PathConv {
    """Materializes the subtree under the entry node.

    ``path_seen`` holds only the ancestors of this branch; a revisit means
    a genuine cycle (flagged, never silently disengaged).
    """
    has path_seen: set[str] = set();
    has res_obj: dict = {};
    has res_val: str = "";
    has is_leaf: bool = False;
    has hit_cycle: bool = False;

    can walk with VNode entry {
        if here.vid in self.path_seen {
            self.hit_cycle = True;
            return;
        }
        if here.kind == "scalar" {
            self.is_leaf = True;
            self.res_val = here.sval;
            return;
        }
        keys = sorted([e.key for e in [edge here ->:Prop:->]]);
        for k in keys {
            child = [here ->:Prop:key == k:->][0];
            sub = PathConv(path_seen=self.path_seen | {here.vid});
            child spawn sub;
            if sub.hit_cycle {
                self.hit_cycle = True;
                return;
            }
            self.res_obj[k] = sub.res_val if sub.is_leaf else sub.res_obj;
        }
    }
}


walker LeafPaths {
    """Enumerates root-to-leaf paths as "path=value" strings."""
    has path_seen: set[str] = set();
    has prefix: str = "";
    has paths: list[str] = [];
    has hit_cycle: bool = False;

    can walk with VNode entry {
        if here.vid in self.path_seen {
            self.hit_cycle = True;
            return;
        }
        if here.kind == "scalar" {
            self.paths.append(self.prefix + "=" + here.sval);
            return;
        }
        keys = sorted([e.key for e in [edge here ->:Prop:->]]);
        for k in keys {
            child = [here ->:Prop:key == k:->][0];
            sub = LeafPaths(path_seen=self.path_seen | {here.vid},
                            prefix=self.prefix + "/" + k);
            child spawn sub;
            self.paths.extend(sub.paths);
            if sub.hit_cycle {
                self.hit_cycle = True;
                return;
            }
        }
    }
}


def _require(vid: str) -> None {
    if vid not in vals {
        raise KeyError(vid);
    }
}


def convert(root_vid: str) -> dict | str {
    _require(root_vid);
    w = vals[root_vid] spawn PathConv();
    if w.hit_cycle {
        raise ValueError("cyclic reference");
    }
    return w.res_val if w.is_leaf else w.res_obj;
}


def leaf_paths(root_vid: str) -> list[str] {
    _require(root_vid);
    w = vals[root_vid] spawn LeafPaths();
    if w.hit_cycle {
        raise ValueError("cyclic reference");
    }
    return sorted(w.paths);
}
