"""OSP lift for dowdiness/canopy#1236 — Cut B′ responsibility and lifetime ledger."""

node Entity {
    has name: str;
}

edge Owns {}
edge Publishes {}
edge Depends {}

walker LedgerWalker {
    has ledger: dict[str, str] = {};
    has claimed: dict[str, bool] = {};
    has seed: str = "";

    can begin with Root entry {
        for e in [-->][?:Entity] {
            if e.name == self.seed {
                self.ledger[self.seed] = self.seed;
                visit [e];
            }
        }
    }

    can step with Entity entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        owner = here.name;
        for child in [here ->:Owns:->][?:Entity] {
            if child.name not in self.ledger {
                self.ledger[child.name] = self.ledger[here.name];
            }
            if child.name not in self.claimed {
                visit [child];
            }
        }
        for proj in [here ->:Publishes:->][?:Entity] {
            if proj.name not in self.ledger {
                self.ledger[proj.name] = owner;
            }
            if proj.name not in self.claimed {
                visit [proj];
            }
        }
    }

    can finish with Root exit {
        report self.ledger;
    }
}

walker ClosureWalker {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};
    has start: str = "";

    can begin with Root entry {
        for e in [-->][?:Entity] {
            if e.name == self.start {
                visit [e];
            }
        }
    }

    can step with Entity entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        visit [here ->:Depends:->];
    }

    can finish with Root exit {
        report self.order;
    }
}

def _wire_ledger(
    owns: list[tuple[str, str]], publishes: list[tuple[str, str]]
) {
    nodes: dict[str, Entity] = {};
    for (parent, child) in owns {
        if parent not in nodes {
            nodes[parent] = Entity(name=parent);
            root ++> nodes[parent];
        }
        if child not in nodes {
            nodes[child] = Entity(name=child);
            root ++> nodes[child];
        }
        nodes[parent] +>:Owns:+> nodes[child];
    }
    for (pub, proj) in publishes {
        if pub not in nodes {
            nodes[pub] = Entity(name=pub);
            root ++> nodes[pub];
        }
        if proj not in nodes {
            nodes[proj] = Entity(name=proj);
            root ++> nodes[proj];
        }
        nodes[pub] +>:Publishes:+> nodes[proj];
    }
}

def _wire_depends(edges: list[tuple[str, str]]) {
    nodes: dict[str, Entity] = {};
    for (src, dst) in edges {
        if src not in nodes {
            nodes[src] = Entity(name=src);
            root ++> nodes[src];
        }
        if dst not in nodes {
            nodes[dst] = Entity(name=dst);
            root ++> nodes[dst];
        }
        nodes[src] +>:Depends:+> nodes[dst];
    }
}

def responsibility_ledger(
    seed: str,
    owns: list[tuple[str, str]],
    publishes: list[tuple[str, str]],
) -> dict[str, str] {
    _wire_ledger(owns, publishes);
    w = root spawn LedgerWalker(seed=seed);
    return w.reports[0] if w.reports else {};
}

def lifetime_owners(
    projection: str,
    chain: list[tuple[str, str]],
) -> list[str] {
    parent_of: dict[str, str] = {};
    for (parent, child) in chain {
        parent_of[child] = parent;
    }
    owners: list[str] = [];
    cur = projection;
    while cur in parent_of {
        cur = parent_of[cur];
        owners.append(cur);
    }
    return sorted(list(set(owners)));
}

def cut_b_prime_closure(
    start: str,
    edges: list[tuple[str, str]],
) -> list[str] {
    _wire_depends(edges);
    w = root spawn ClosureWalker(start=start);
    return w.reports[0] if w.reports else [];
}
