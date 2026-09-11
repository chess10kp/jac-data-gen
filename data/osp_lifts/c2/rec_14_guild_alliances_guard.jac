"""Guild alliance registry lifted to OSP.

Guilds become nodes, pacts become undirected AlliedWith edges. The deque
flood becomes a claiming walker; the claim map is the explicit cycle
policy (jac walkers do not dedupe), and PactCheck disengages early the
moment the queried tag surfaces.
"""
node Guild {
    has tag: str;
}
edge AlliedWith {}

"""Loader handle: guild tags resolve through this lookup map."""
obj League {
    has roster: dict[str, Guild];

    def resolve(tag: str) -> Guild | None {
        return self.roster.get(tag);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def build_league(tags: list[str], pacts: list[tuple[str, str]]) -> League {
    net = League(roster={});
    for t in tags {
        g = Guild(tag=t);
        root ++> g;
        net.roster[t] = g;
    }
    for (a, b) in pacts {
        ga = net.roster[a];
        gb = net.roster[b];
        ga +>:AlliedWith:+> gb;
        gb +>:AlliedWith:+> ga;
    }
    return net;
}

walker BlocFlood {
    has claimed: dict[str, bool] = {};
    has tags: list[str] = [];

    can step with Guild entry {
        if here.tag in self.claimed {
            skip;
        }
        self.claimed[here.tag] = True;
        self.tags.append(here.tag);
        visit [->:AlliedWith:->] else { disengage; }
    }
}

walker PactCheck {
    has target: str;
    has found: bool = False;
    has claimed: dict[str, bool] = {};
    has started: bool = False;

    can step with Guild entry {
        if not self.started {
            self.started = True;
            self.claimed[here.tag] = True;
            visit [->:AlliedWith:->] else { disengage; }
        } else {
            if here.tag == self.target {
                self.found = True;
                disengage;
            }
            if here.tag in self.claimed {
                skip;
            }
            self.claimed[here.tag] = True;
            visit [->:AlliedWith:->] else { disengage; }
        }
    }
}

"""Every guild in ``tag``'s alliance bloc, including itself (sorted)."""
def allies_of(net: League, tag: str) -> list[str] {
    start = net.resolve(tag);
    if start is None {
        return [];
    }
    w = start spawn BlocFlood();
    return sorted(w.tags);
}

"""True when ``tag_b`` sits anywhere inside ``tag_a``'s pact web."""
def allied_with(net: League, tag_a: str, tag_b: str) -> bool {
    start = net.resolve(tag_a);
    if start is None {
        return False;
    }
    if net.resolve(tag_b) is None {
        return False;
    }
    if tag_a == tag_b {
        return True;
    }
    w = start spawn PactCheck(target=tag_b);
    return w.found;
}

test "alliance bloc multiset" {
    net = build_league(["WOLF", "HAWK", "BEAR", "TIDE", "DUNE"], [("WOLF", "HAWK"), ("HAWK", "BEAR"), ("TIDE", "DUNE")]);
    assert allies_of(net, "WOLF") == ["BEAR", "HAWK", "WOLF"];
    assert allies_of(net, "TIDE") == ["DUNE", "TIDE"];
}

test "pact checks incl self" {
    net = build_league(["A", "B", "C", "D"], [("A", "B"), ("B", "C")]);
    assert allied_with(net, "A", "C");
    assert allied_with(net, "A", "A");
    assert allied_with(net, "D", "D");
    assert not allied_with(net, "C", "D");
}

test "pact ring terminates" {
    net = build_league(["A", "B", "C"], [("A", "B"), ("B", "C"), ("C", "A")]);
    assert allies_of(net, "B") == ["A", "B", "C"];
    assert allied_with(net, "C", "A");
}

test "unknown tags" {
    net = build_league(["A"], []);
    assert allies_of(net, "NOPE") == [];
    assert not allied_with(net, "A", "NOPE");
    assert not allied_with(net, "NOPE", "A");
}

test "diamond pact web closes fully" {
    net = build_league(["A", "B", "C", "D"], [("A", "B"), ("A", "C"), ("B", "D"), ("C", "D")]);
    assert allies_of(net, "A") == ["A", "B", "C", "D"];
}
