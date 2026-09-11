"""Rebuild-fanout analysis, lifted to OSP.

Generated units become Unit nodes; per-unit import lists become typed
Imports edges (unit -> the source unit it includes); the reverse-
adjacency BFS becomes a walker over the reverse edge direction whose
claim map is the once-per-unit guard -- diamond confluence and import
cycles both terminate, and a unit reached via two import paths rebuilds
once. The unit registry stays as the loader's lookup map so import-only
names propagate without counting as units.
Ref: alexstanciu-1/simplecpp#218
"""
node Unit {
    has uid: str;
}
edge Imports {}

"""Unit-graph handle: known unit ids resolve through the lookup map."""
obj UnitGraph {
    has units: dict[str, Unit];
    has nodes: dict[str, Unit];

    def resolve(uid: str) -> Unit | None {
        return self.nodes.get(uid);
    }
}

"""Deterministic fresh-graph builder from a {unit: [imports]} spec."""
def load_units(units: dict) -> UnitGraph {
    ug = UnitGraph(units={}, nodes={});
    names: set[str] = set(units.keys());
    for k in units.keys() {
        imps: list[str] = units[k];
        for d in imps {
            names.add(d);
        }
    }
    for n in names {
        u = Unit(uid=n);
        root ++> u;
        ug.nodes[n] = u;
    }
    for k in units.keys() {
        ug.units[k] = ug.nodes[k];
    }
    for k in units.keys() {
        imps: list[str] = units[k];
        for d in imps {
            dep = ug.resolve(d);
            if dep is not None {
                ug.nodes[k] +>:Imports:+> dep;
            }
        }
    }
    return ug;
}

"""Transitive importers of the spawn point, once per unit."""
walker DependentWalk {
    has claimed: dict[str, bool] = {};
    has hit: list[str] = [];

    can step with Unit entry {
        if here.uid in self.claimed {
            skip;
        }
        self.claimed[here.uid] = True;
        self.hit.append(here.uid);
        visit [<-:Imports:<-];  # reverse direction: units that import me
    }
}

"""Sorted ids of every unit transitively importing a changed source."""
def affected(units: dict, changed: list[str]) -> list[str] {
    ug = load_units(units);
    claimed: dict[str, bool] = {};
    hit: list[str] = [];
    for c in changed {
        n = ug.resolve(c);
        if n is None {
            continue;
        }
        n spawn DependentWalk(claimed=claimed, hit=hit);
    }
    out: list[str] = [];
    for h in hit {
        if h in ug.units {
            out.append(h);
        }
    }
    return sorted(out);
}

"""How many units an edit of ``changed`` sources would rebuild."""
def fanout(units: dict, changed: list[str]) -> int {
    return len(affected(units, changed));
}
