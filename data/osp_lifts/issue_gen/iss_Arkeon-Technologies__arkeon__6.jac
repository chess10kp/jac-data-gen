"""Arkeon-Technologies/arkeon#6 — filtered neighborhood traversal (OSP lift)."""

obj TraversalGraph {
    def link(a: str, b: str, kind: str) -> None;
    def traverse(start: str, depth: int, allowed_kinds: set[str]) -> list[str];
    def shortest_path(
        src: str, dst: str, max_depth: int, allowed_kinds: set[str]
    ) -> list[str] | None;
}

node Vertex {
    has vid: str;
}

edge Rel: Vertex --> Vertex {
    has kind: str;
}

def _ensure_vertex(vid: str) -> Vertex {
    for v in [root-->][?:Vertex] {
        if v.vid == vid {
            return v;
        }
    }
    return root ++> Vertex(vid=vid);
}

def _kind_map(allowed_kinds: set[str]) -> dict[str, bool] {
    out: dict[str, bool] = {};
    for k in allowed_kinds {
        out[k] = True;
    }
    return out;
}

walker FilterReachWalker {
    has start: str;
    has max_depth: int;
    has allowed: dict[str, bool] = {};
    has claimed: dict[str, bool] = {};
    has depth_map: dict[str, int] = {};
    has hits: list[str] = [];

    can begin with Root entry {
        matches = [root-->][?:Vertex, vid == self.start];
        if matches {
            self.depth_map[self.start] = 0;
            visit [matches[0]];
        } else {
            disengage;
        }
    }

    can step with Vertex entry {
        if here.vid in self.claimed {
            skip;
        }
        self.claimed[here.vid] = True;
        d = self.depth_map.get(here.vid, 0);
        if here.vid != self.start {
            self.hits.append(here.vid);
        }
        if d >= self.max_depth {
            skip;
        }
        for k in self.allowed {
            if not self.allowed[k] {
                continue;
            }
            for tgt in [here ->:Rel:kind == k:->][?:Vertex] {
                if tgt.vid not in self.claimed {
                    self.depth_map[tgt.vid] = d + 1;
                    visit [tgt];
                }
            }
        }
    }
}

walker ShortestWalker {
    has src: str;
    has dst: str;
    has max_depth: int;
    has allowed: dict[str, bool] = {};
    has claimed: dict[str, bool] = {};
    has parent: dict[str, str] = {};
    has depth_map: dict[str, int] = {};
    has found: bool = False;
    has result: list[str] = [];

    can begin with Root entry {
        matches = [root-->][?:Vertex, vid == self.src];
        if matches {
            self.depth_map[self.src] = 0;
            self.parent[self.src] = "";
            visit [matches[0]];
        } else {
            disengage;
        }
    }

    can step with Vertex entry {
        if here.vid in self.claimed {
            skip;
        }
        self.claimed[here.vid] = True;
        if here.vid == self.dst {
            self.found = True;
            path: list[str] = [];
            cur = self.dst;
            while cur != "" {
                path.append(cur);
                if cur == self.src {
                    break;
                }
                cur = self.parent.get(cur, "");
            }
            self.result = [];
            i = len(path) - 1;
            while i >= 0 {
                self.result.append(path[i]);
                i -= 1;
            }
            disengage;
        }
        d = self.depth_map.get(here.vid, 0);
        if d >= self.max_depth {
            skip;
        }
        for k in self.allowed {
            if not self.allowed[k] {
                continue;
            }
            for tgt in [here ->:Rel:kind == k:->][?:Vertex] {
                if tgt.vid not in self.claimed {
                    self.parent[tgt.vid] = here.vid;
                    self.depth_map[tgt.vid] = d + 1;
                    visit [tgt];
                }
            }
        }
    }
}

impl TraversalGraph.link(a: str, b: str, kind: str) -> None {
    src = _ensure_vertex(a);
    dst = _ensure_vertex(b);
    src +>:Rel(kind=kind):+> dst;
}

impl TraversalGraph.traverse(start: str, depth: int, allowed_kinds: set[str]) -> list[str] {
    matches = [root-->][?:Vertex, vid == start];
    if not matches {
        return [];
    }
    w = root spawn FilterReachWalker(
        start=start,
        max_depth=depth,
        allowed=_kind_map(allowed_kinds),
        claimed={},
        depth_map={},
        hits=[],
    );
    return sorted(w.hits);
}

impl TraversalGraph.shortest_path(
    src: str, dst: str, max_depth: int, allowed_kinds: set[str]
) -> list[str] | None {
    if src == dst {
        for v in [root-->][?:Vertex] {
            if v.vid == src {
                return [src];
            }
        }
        return None;
    }
    src_matches = [root-->][?:Vertex, vid == src];
    dst_matches = [root-->][?:Vertex, vid == dst];
    if not src_matches or not dst_matches {
        return None;
    }
    w = root spawn ShortestWalker(
        src=src,
        dst=dst,
        max_depth=max_depth,
        allowed=_kind_map(allowed_kinds),
        claimed={},
        parent={},
        depth_map={},
        found=False,
        result=[],
    );
    if w.found {
        return w.result;
    }
    return None;
}
