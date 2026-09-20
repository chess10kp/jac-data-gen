"""
Stewie-pixel/claude-with-leetcode#158 — Reconstruct Itinerary / Eulerian path.
"""

node Airport {
    has code: str;
    has remaining: dict[str, int] = {};
}

edge Flight {}

walker HierWalk {
    has route: list[str] = [];
    has claimed: dict[str, bool] = {};
    has code_map: dict[str, Airport] = {};

    can walk with Airport entry {
        picked: bool = True;
        while picked {
            picked = False;
            best: str = "";
            for dc in here.remaining {
                cnt = here.remaining[dc];
                if cnt > 0 {
                    claim_key: str = here.code + ">" + dc + ">" + str(cnt);
                    if claim_key not in self.claimed {
                        if best == "" or dc < best {
                            best = dc;
                            picked = True;
                        }
                    }
                }
            }
            if picked {
                claim_key2: str = here.code + ">" + best + ">" + str(here.remaining[best]);
                self.claimed[claim_key2] = True;
                here.remaining[best] -= 1;
                child = self.code_map[best];
                visit :0: [child];
            }
        }
        self.route.append(here.code);
        print("hier", here.code, self.route);
    }
}

walker DemoWalk {
    has claimed: dict[str, bool] = {};

    can probe with Airport entry {
        if here.code in self.claimed {
            skip;
        }
        self.claimed[here.code] = True;
        print("demo", here.code);
        kids: list[Airport] = [here ->:Flight:->][?:Airport];
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def eulerian_path(start: str, edges: list[tuple[str, str]]) -> list[str] {
    code_map: dict[str, Airport] = {};
    for pair in edges {
        u = pair[0];
        v = pair[1];
        if u not in code_map {
            nd_u = Airport(code=u);
            root ++> nd_u;
            code_map[u] = nd_u;
        }
        if v not in code_map {
            nd_v = Airport(code=v);
            root ++> nd_v;
            code_map[v] = nd_v;
        }
        src = code_map[u];
        dst = code_map[v];
        src +>:Flight:+> dst;
        if v not in src.remaining {
            src.remaining[v] = 0;
        }
        src.remaining[v] += 1;
    }
    if start not in code_map {
        return [start];
    }
    start_node = code_map[start];
    w = start_node spawn HierWalk(route=[], claimed={}, code_map=code_map);
    out: list[str] = [];
    idx = len(w.route) - 1;
    while idx >= 0 {
        out.append(w.route[idx]);
        idx -= 1;
    }
    return out;
}

def find_itinerary(tickets: list[list[str]]) -> list[str] {
    edges: list[tuple[str, str]] = [];
    for ticket in tickets {
        edges.append((ticket[0], ticket[1]));
    }
    return eulerian_path("JFK", edges);
}

with entry {
    demo_a = Airport(code="JFK");
    root ++> demo_a;
    demo_a spawn DemoWalk(claimed={});
}

"""
Stewie-pixel/claude-with-leetcode#158 — Reconstruct Itinerary / Eulerian path.
"""

node Airport {
    has code: str;
    has remaining: dict[str, int] = {};
}

edge Flight {}

walker HierWalk {
    has route: list[str] = [];
    has claimed: dict[str, bool] = {};
    has code_map: dict[str, Airport] = {};

    can walk with Airport entry {
        picked: bool = True;
        while picked {
            picked = False;
            best: str = "";
            for dc in here.remaining {
                cnt = here.remaining[dc];
                if cnt > 0 {
                    claim_key: str = here.code + ">" + dc + ">" + str(cnt);
                    if claim_key not in self.claimed {
                        if best == "" or dc < best {
                            best = dc;
                            picked = True;
                        }
                    }
                }
            }
            if picked {
                claim_key2: str = here.code + ">" + best + ">" + str(here.remaining[best]);
                self.claimed[claim_key2] = True;
                here.remaining[best] -= 1;
                child = self.code_map[best];
                visit :0: [child];
            }
        }
        self.route.append(here.code);
        print("hier", here.code, self.route);
    }
}

walker DemoWalk {
    has claimed: dict[str, bool] = {};

    can probe with Airport entry {
        if here.code in self.claimed {
            skip;
        }
        self.claimed[here.code] = True;
        print("demo", here.code);
        kids: list[Airport] = [here ->:Flight:->][?:Airport];
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def eulerian_path(start: str, edges: list[tuple[str, str]]) -> list[str] {
    code_map: dict[str, Airport] = {};
    for pair in edges {
        u = pair[0];
        v = pair[1];
        if u not in code_map {
            nd_u = Airport(code=u);
            root ++> nd_u;
            code_map[u] = nd_u;
        }
        if v not in code_map {
            nd_v = Airport(code=v);
            root ++> nd_v;
            code_map[v] = nd_v;
        }
        src = code_map[u];
        dst = code_map[v];
        src +>:Flight:+> dst;
        if v not in src.remaining {
            src.remaining[v] = 0;
        }
        src.remaining[v] += 1;
    }
    if start not in code_map {
        return [start];
    }
    start_node = code_map[start];
    w = start_node spawn HierWalk(route=[], claimed={}, code_map=code_map);
    out: list[str] = [];
    idx = len(w.route) - 1;
    while idx >= 0 {
        out.append(w.route[idx]);
        idx -= 1;
    }
    return out;
}

def find_itinerary(tickets: list[list[str]]) -> list[str] {
    edges: list[tuple[str, str]] = [];
    for ticket in tickets {
        edges.append((ticket[0], ticket[1]));
    }
    return eulerian_path("JFK", edges);
}

with entry {
    demo_a = Airport(code="JFK");
    root ++> demo_a;
    demo_a spawn DemoWalk(claimed={});
}

test "empty_tickets" {
    got = find_itinerary([]);
    assert got == ["JFK"];
}

test "single_ticket" {
    got = find_itinerary([["JFK", "AAA"]]);
    assert got == ["JFK", "AAA"];
}

test "classic_three_leg" {
    tix: list[list[str]] = [["MUC", "LHR"], ["JFK", "MUC"], ["LHR", "SFO"]];
    got = find_itinerary(tix);
    assert got == ["JFK", "MUC", "LHR", "SFO"];
}

test "lex_smallest_eulerian" {
    tix: list[list[str]] = [
        ["JFK", "SFO"],
        ["JFK", "ATL"],
        ["SFO", "ATL"],
        ["ATL", "JFK"],
        ["ATL", "SFO"]
    ];
    got = find_itinerary(tix);
    assert got == ["JFK", "ATL", "JFK", "SFO", "ATL", "SFO"];
}

test "eulerian_unknown_start" {
    got = eulerian_path("ZZZ", []);
    assert got == ["ZZZ"];
}

test "parallel_edges_lex" {
    edges: list[tuple[str, str]] = [("A", "B"), ("A", "B"), ("B", "A")];
    got = eulerian_path("A", edges);
    assert got == ["A", "B", "A", "B"];
}
