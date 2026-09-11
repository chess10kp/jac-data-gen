"""Factual-memory graph traversal, lifted to OSP.

Typed relations become Entity nodes connected THROUGH typed RelNode
carriers (FromSrc then ToDst), so the relation kind is graph payload the
walker can filter on mid-traversal. The deque BFS loops become flooding
walkers; the hop-budgeted query uses a best-remaining-fuel map so the
reachable-within-depth set is exact and order-independent. Claim/fuel
maps are the explicit cycle policy -- jac walkers do not dedupe.
Ref: hleserg/atman#1185
"""
node Entity {
    has name: str;
}
node RelNode {
    has kind: str;
}
edge FromSrc {}  # entity -> its outgoing relation
edge ToDst {}    # relation -> target entity

"""Loader handle: names resolve through this lookup map."""
obj Memory {
    has entities: dict[str, Entity];
    has names: list[str];

    def resolve(name: str) -> Entity | None {
        return self.entities.get(name);
    }
}

def new_memory() -> Memory {
    return Memory(entities={}, names=[]);
}

def remember(mem: Memory, entity: str) -> None {
    e = Entity(name=entity);
    root ++> e;
    mem.entities[entity] = e;
    mem.names.append(entity);
}

"""Directed relation ``src --kind--> dst``."""
def link(mem: Memory, src: str, kind: str, dst: str) -> None {
    if src not in mem.entities {
        remember(mem, src);
    }
    if dst not in mem.entities {
        remember(mem, dst);
    }
    r = RelNode(kind=kind);
    root ++> r;
    mem.entities[src] +>:FromSrc:+> r;
    r +>:ToDst:+> mem.entities[dst];
}

"""Direct relations of ``entity``, optionally filtered by kind. Sorted."""
def neighbors(mem: Memory, entity: str, kinds: list | None = None) -> list[str] {
    start = mem.resolve(entity);
    if start is None {
        return [];
    }
    hits: dict[str, bool] = {};
    for r in [start->:FromSrc:->] {
        if kinds is not None and r.kind not in kinds {
            continue;
        }
        for d in [r->:ToDst:->] {
            hits[d.name] = True;
        }
    }
    return sorted(hits.keys());
}

walker HopFlood {
    # Cycle/depth policy: expand a name again only on a strictly larger
    # remaining budget; guarantees termination and an order-independent
    # reachable-within-depth set even on cyclic relation graphs.
    has fuel: dict[str, int] = {};
    has hops: int = 0;
    has budget: int = 0;
    has kinds: list | None = None;
    has found: list[str] = [];
    has root_name: str = "";

    can hop with Entity entry {
        prev = -1;
        if here.name in self.fuel {
            prev = self.fuel[here.name];
        }
        if prev >= self.hops {
            skip;
        }
        self.fuel[here.name] = self.hops;
        # record each entity once, at first arrival
        if here.name != self.root_name and prev == -1 {
            self.found.append(here.name);
        }
        if self.hops < self.budget {
            for r in [here->:FromSrc:->] {
                if self.kinds is not None and r.kind not in self.kinds {
                    continue;
                }
                for d in [r->:ToDst:->] {
                    d spawn HopFlood(fuel=self.fuel, hops=self.hops + 1, budget=self.budget, kinds=self.kinds, found=self.found, root_name=self.root_name);
                }
            }
        }
    }
}

"""All entities reachable from ``entity`` within ``depth`` hops
(over ``kinds`` when given), inclusive, sorted."""
def related_within(mem: Memory, entity: str, depth: int, kinds: list | None = None) -> list[str] {
    start = mem.resolve(entity);
    if start is None {
        return [entity];
    }
    w = start spawn HopFlood(fuel={}, hops=0, budget=depth, kinds=kinds, root_name=entity);
    # dict-key dedupe keeps the result a set even if racing sibling
    # arrivals append twice.
    uniq: dict[str, bool] = {};
    for n in w.found {
        uniq[n] = True;
    }
    keys = sorted(uniq.keys());
    return sorted([entity] + keys);
}

obj HitSink {
    has hit: bool = False;
}

walker ReachFlood {
    # Cycle policy: claim-once; revisits are skipped, floods terminate.
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has sink: HitSink | None = None;

    can walk with Entity entry {
        if here.name == self.target and self.sink is not None and not (self.sink.hit) {
            self.sink.hit = True;
            disengage;
        }
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        for r in [here->:FromSrc:->] {
            for d in [r->:ToDst:->] {
                d spawn ReachFlood(claimed=self.claimed, target=self.target, sink=self.sink);
            }
        }
    }
}

"""True when ``dst`` is reachable from ``src`` over any relations."""
def are_related(mem: Memory, src: str, dst: str) -> bool {
    start = mem.resolve(src);
    if start is None or dst not in mem.entities or src == dst {
        return False;
    }
    sink = HitSink(hit=False);
    start spawn ReachFlood(claimed={}, target=dst, sink=sink);
    return sink.hit;
}


test "one-hop neighbors filter by relation kind" {
    mem = new_memory();
    link(mem, "ada", "knows", "bob");
    link(mem, "ada", "mentions", "ci");
    assert neighbors(mem, "ada") == ["bob", "ci"];
    assert neighbors(mem, "ada", ["knows"]) == ["bob"];
    assert neighbors(mem, "ghost") == [];
}

test "budgeted reachability crosses two hops but stops at three" {
    mem = new_memory();
    link(mem, "a", "knows", "b");
    link(mem, "b", "knows", "c");
    link(mem, "c", "knows", "d");
    assert related_within(mem, "a", 1) == ["a", "b"];
    assert related_within(mem, "a", 2) == ["a", "b", "c"];
    assert related_within(mem, "a", 9) == ["a", "b", "c", "d"];
    assert related_within(mem, "a", 3, ["mentions"]) == ["a"];
}

test "unbounded reachability over mixed kinds" {
    mem = new_memory();
    link(mem, "x", "knows", "y");
    link(mem, "y", "mentions", "z");
    assert are_related(mem, "x", "z");
    assert not are_related(mem, "z", "x");
    assert not are_related(mem, "x", "x");
}

test "relation cycle terminates without truncation" {
    cyc = new_memory();
    link(cyc, "p", "knows", "q");
    link(cyc, "q", "knows", "p");
    link(cyc, "q", "knows", "r");
    assert related_within(cyc, "p", 7) == ["p", "q", "r"];
    assert are_related(cyc, "p", "q");
}
