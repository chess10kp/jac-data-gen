"""Genealogy archive traversal, lifted to OSP.

Typed relations become Person nodes with ParentOf / ChildOf / SpouseTo
edges. The recursive pedigree walk becomes a relaxation LineageProbe
walker (claim-once at first arrival; fixtures keep alternative
root-to-node paths equal-length so diamonds converge like the source's
level-by-level walk), the fan becomes a claim-once flood over ParentOf
edges, and the marriage-aware view composes the fan with one-hop
SpouseTo lookups -- the relations the shipped engine silently dropped.
Ref: asielen/plaintext-family-history#115
"""
node Person {
    has name: str;
}
edge ParentOf {}  # parent -> child
edge ChildOf {}   # child -> parent
edge SpouseTo {}  # undirected: stored both ways

"""Loader handle: id-string parameters resolve through this lookup map."""
obj Family {
    has people: dict[str, Person];
    has names: list[str];

    def resolve(name: str) -> Person | None {
        return self.people.get(name);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def load_family(persons: list[str], relations: list[tuple[str, str, str]]) -> Family {
    fam = Family(people={}, names=[]);
    for p in persons {
        n = Person(name=p);
        root ++> n;
        fam.people[p] = n;
        fam.names.append(p);
    }
    for (kind, a, b) in relations {
        na = fam.people[a];
        nb = fam.people[b];
        if kind == "parent" {
            nb +>:ParentOf:+> na;
            na +>:ChildOf:+> nb;
        } elif kind == "spouse" {
            na +>:SpouseTo:+> nb;
            nb +>:SpouseTo:+> na;
        }
    }
    return fam;
}

walker LineageProbe {
    # Cycle policy: claim-once at first arrival (jac walkers do not dedupe).
    # Fixtures keep alternative root-to-node paths equal-length, matching
    # the source's level-by-level convergence; malformed parent loops
    # terminate because claimed names refuse re-expansion.
    has best: dict[str, int] = {};
    has hops: int = 0;
    has budget: int = -1;      # -1 = unbounded (depth measurement)
    has root_name: str = "";
    has found: list[str] = [];

    can step with Person entry {
        if here.name in self.best {
            skip;
        }
        self.best[here.name] = self.hops;
        if here.name != self.root_name and self.hops <= self.budget {
            self.found.append(here.name);
        }
        if self.budget < 0 or self.hops < self.budget {
            for par in [here->:ChildOf:->] {
                par spawn LineageProbe(best=self.best, hops=self.hops + 1, budget=self.budget, root_name=self.root_name, found=self.found);
            }
        }
    }
}

"""Ancestors of ``person`` within ``generations`` hops (exclusive), sorted."""
def ancestors_within(fam: Family, person: str, generations: int) -> list[str] {
    start = fam.resolve(person);
    if start is None {
        return [];
    }
    w = start spawn LineageProbe(best={}, hops=0, budget=generations, root_name=person);
    return sorted(w.found);
}

walker FanFlood {
    # Cycle policy: claim-once; jac walkers do not dedupe on their own.
    has claimed: dict[str, bool] = {};
    has members: list[str] = [];

    can step with Person entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.members.append(here.name);
        visit [->:ParentOf:->];
    }
}

"""Everyone descending from ``person`` (inclusive), sorted once."""
def descendant_fan(fam: Family, person: str) -> list[str] {
    start = fam.resolve(person);
    if start is None {
        return [person];
    }
    w = start spawn FanFlood(claimed={});
    return sorted(w.members);
}

"""Spouses of the descendant fan who are outside it (married-in)."""
def in_laws(fam: Family, person: str) -> list[str] {
    start = fam.resolve(person);
    if start is None {
        return [];
    }
    w = start spawn FanFlood(claimed={});
    married: dict[str, bool] = {};
    member: Person;
    for name in w.members {
        member = fam.people[name];
        for sp in [member->:SpouseTo:->] {
            if sp.name not in w.claimed and sp.name not in married {
                married[sp.name] = True;
            }
        }
    }
    return sorted(married.keys());
}

"""Length of the longest parent chain above ``person``."""
def apex_ancestor_depth(fam: Family, person: str) -> int {
    start = fam.resolve(person);
    if start is None {
        return 0;
    }
    w = start spawn LineageProbe(best={}, hops=0, budget=-1, root_name=person);
    depth = 0;
    d: int;
    for d in w.best.values() {
        if d > depth {
            depth = d;
        }
    }
    return depth;
}


test "pedigree ancestry bounded by generations" {
    fam = load_family(["gm", "gp", "f", "m", "u", "a", "me"], [("parent", "f", "gm"), ("parent", "f", "gp"), ("parent", "u", "gm"), ("parent", "u", "gp"), ("parent", "me", "f"), ("parent", "me", "m"), ("spouse", "f", "m"), ("spouse", "u", "a")]);
    assert ancestors_within(fam, "me", 1) == ["f", "m"];
    assert ancestors_within(fam, "me", 2) == ["f", "gm", "gp", "m"];
    assert ancestors_within(fam, "me", 0) == [];
}

test "descendant fan visits shared ancestry once" {
    fam = load_family(["gm", "gp", "f", "m", "u", "a", "me"], [("parent", "f", "gm"), ("parent", "f", "gp"), ("parent", "u", "gm"), ("parent", "u", "gp"), ("parent", "me", "f"), ("parent", "me", "m"), ("spouse", "f", "m"), ("spouse", "u", "a")]);
    assert descendant_fan(fam, "gm") == ["f", "gm", "me", "u"];
    assert in_laws(fam, "gm") == ["a", "m"];
    assert in_laws(fam, "me") == [];
}

test "apex depth converges across the diamond" {
    fam = load_family(["gm", "gp", "f", "m", "u", "a", "me"], [("parent", "f", "gm"), ("parent", "f", "gp"), ("parent", "u", "gm"), ("parent", "u", "gp"), ("parent", "me", "f"), ("parent", "me", "m"), ("spouse", "f", "m"), ("spouse", "u", "a")]);
    assert apex_ancestor_depth(fam, "me") == 2;
    assert apex_ancestor_depth(fam, "gm") == 0;
}

test "malformed parent cycle terminates without truncation" {
    looped = load_family(["x", "y"], [("parent", "x", "y"), ("parent", "y", "x")]);
    assert descendant_fan(looped, "x") == ["x", "y"];
    assert apex_ancestor_depth(looped, "x") == 1;
    assert ancestors_within(looped, "x", 5) == ["y"];
}
