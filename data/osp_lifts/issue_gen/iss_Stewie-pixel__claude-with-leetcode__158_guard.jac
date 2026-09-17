"""
Idiomatic OSP lift of Stewie-pixel/claude-with-leetcode#158
(Reconstruct Itinerary / Hierholzer Eulerian path with lexical greedy).

Python machinery replaced: defaultdict adjacency heaps + explicit stack ->
Airport nodes whose sorted `dests` lists are consumed in place by the
iterative Hierholzer loop (pop-min = heap pop).
"""
node Airport {
    has code: str;
    has dests: list[str] = [];
}

# Build the ticket multigraph; each origin keeps a sorted multiset of dests.
def build_graph(tk: list[tuple[str, str]]) -> dict[str, Airport] {
    nodes: dict[str, Airport] = {};
    for t in tk {
        u: str = t[0];
        v: str = t[1];
        if u not in nodes {
            nd = Airport(code=u);
            root ++> nd;
            nodes[u] = nd;
        }
        if v not in nodes {
            nd2 = Airport(code=v);
            root ++> nd2;
            nodes[v] = nd2;
        }
        nodes[u].dests.append(v);
    }
    for code in sorted(nodes.keys()) {
        nodes[code].dests = sorted(nodes[code].dests);
    }
    return nodes;
}

# Hierholzer: follow smallest lexical unused edge until stuck, pop to path.
def reconstruct_itinerary(tk: list[tuple[str, str]]) -> list[str] {
    nodes: dict[str, Airport] = build_graph(tk);
    start: Airport | None = nodes.get("JFK");
    if start is None {
        # Unknown-start tolerance: itinerary is just the fixed origin.
        return ["JFK"];
    }
    stack: list[Airport] = [start];
    path: list[str] = [];
    while len(stack) > 0 {
        cur: Airport = stack[-1];
        if len(cur.dests) > 0 {
            nxt_code: str = cur.dests.pop(0);
            stack.append(nodes[nxt_code]);
        } else {
            dead: Airport = stack.pop();
            path.append(dead.code);
        }
    }
    out: list[str] = [];
    i: int = len(path) - 1;
    while i >= 0 {
        out.append(path[i]);
        i -= 1;
    }
    return out;
}

# Demo walker: replays a finished itinerary over the graph, printing legs.
walker Traveler {
    has itin: list[str] = [];
    has nodes: dict[str, Airport] = {};
    has pos: int = 0;
    can fly with Airport entry {
        print("leg", self.pos, "->", here.code);
        self.pos += 1;
        if self.pos < len(self.itin) {
            visit self.nodes[self.itin[self.pos]];
        } else {
            disengage;
        }
    }
}

with entry {
    tk: list[tuple[str, str]] = [("JFK", "SFO"), ("JFK", "ATL"), ("SFO", "ATL"), ("ATL", "JFK"), ("ATL", "SFO")];
    it = reconstruct_itinerary(tk);
    print("itinerary:", it);
    nodes = build_graph(tk);
    st: Airport | None = nodes.get(it[0]);
    if st is not None {
        root spawn Traveler(itin=it, nodes=nodes);
    }
}

test "lexical_greedy_classic" {
    tk = [("JFK", "SFO"), ("JFK", "ATL"), ("SFO", "ATL"), ("ATL", "JFK"), ("ATL", "SFO")];
    assert reconstruct_itinerary(tk) == ["JFK", "ATL", "SFO", "ATL", "JFK", "SFO"];
}

test "splice_backtrack_dead_end" {
    tk = [("JFK", "KUL"), ("JFK", "NRT"), ("NRT", "JFK")];
    assert reconstruct_itinerary(tk) == ["JFK", "NRT", "JFK", "KUL"];
}

test "parallel_tickets_multigraph" {
    tk = [("JFK", "A"), ("A", "JFK"), ("JFK", "A")];
    assert reconstruct_itinerary(tk) == ["JFK", "A", "JFK", "A"];
}

test "unknown_start_tolerant" {
    tk = [("AAA", "BBB")];
    assert reconstruct_itinerary(tk) == ["JFK"];
}

test "empty_tickets_returns_origin" {
    tk: list[tuple[str, str]] = [];
    assert reconstruct_itinerary(tk) == ["JFK"];
}

test "build_graph_sorted_multiset" {
    nodes = build_graph([("JFK", "Z"), ("JFK", "A"), ("JFK", "A")]);
    assert nodes["JFK"].dests == ["A", "A", "Z"];
}
