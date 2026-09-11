"""Schema dependency impact lifted to OSP (paulushcgcj/sqlfy#76).

The flat object/edge tables and their per-step rescans die: containment
becomes a typed ``Contains`` edge (table --> column), foreign keys become
typed ``References`` edges (dependent --> referenced), and the depth-bounded
dependents walk becomes ``RefWalk`` carrying its hop budget down through
per-branch sub-spawns. Revisits are skipped via the explicit claim-map;
the depth default of 3 is preserved. All mutable state lives on a
per-instance ``SchemaGraph`` handle -- every test constructs a fresh
instance, no module-level globals.
"""

node SchemaObj {
    has name: str;
    has kind: str;  # "table" | "column"
}

edge Contains: SchemaObj --> SchemaObj {}

edge References: SchemaObj --> SchemaObj {}


walker RefWalk {
    """Depth-budgeted dependents/references walk over References edges."""
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has budget: int = -1;
    has reverse: bool = False;

    can step with SchemaObj entry {
        if here.name in self.claimed {
            return;  # revisit: skip silently
        }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        if self.budget == 0 {
            return;
        }
        next_budget = self.budget - 1;
        if self.budget < 0 {
            next_budget = -1;
        }
        if self.reverse {
            for nb in [here <-:References:<-] {
                sub = RefWalk(claimed=self.claimed, budget=next_budget,
                              reverse=True);
                nb spawn sub;
                self.found.extend(sub.found);
            }
        } else {
            for nb in [here ->:References:->] {
                sub = RefWalk(claimed=self.claimed, budget=next_budget,
                              reverse=False);
                nb spawn sub;
                self.found.extend(sub.found);
            }
        }
    }
}


# Per-instance graph handle: the name lookup map is domain API; each test
# builds its own SchemaGraph so no state leaks between runs.
obj SchemaGraph {
    has objs: dict[str, SchemaObj] = {};

    def add_table(name: str) -> None {
        if name in self.objs {
            raise ValueError("duplicate");
        }
        n = SchemaObj(name=name, kind="table");
        root ++> n;
        self.objs[name] = n;
    }

    def add_column(table: str, col: str) -> None {
        full = "{}.{}".format(table, col);
        if table not in self.objs {
            raise KeyError(table);
        }
        c = SchemaObj(name=full, kind="column");
        root ++> c;
        self.objs[full] = c;
        self.objs[table] +>:Contains:+> c;
    }

    def add_fk(dependent: str, referenced: str) -> None {
        for t in (dependent, referenced) {
            if t not in self.objs or self.objs[t].kind != "table" {
                raise KeyError(t);
            }
        }
        self.objs[dependent] +>:References:+> self.objs[referenced];
    }

    # dependents/references walk from seed within depth
    def _walk(seed: str, depth: int, reverse: bool) -> list[str] {
        w = self.objs[seed] spawn RefWalk(budget=depth, reverse=reverse);
        return w.found;
    }

    def impact(obj_name: str, direction: str = "downstream",
               depth: int = 3) -> list[str] {
        # sorted object names affected by changing obj_name, within depth
        if obj_name not in self.objs {
            raise KeyError(obj_name);
        }
        seed = obj_name;
        if self.objs[obj_name].kind == "column" {
            parents = [self.objs[obj_name] <-:Contains:<-];
            seed = parents[0].name;  # column anchors its table
        }
        hit: set[str] = set();
        if direction == "downstream" {
            for x in self._walk(seed, depth, True) {
                hit.add(x);
            }
        } elif direction == "upstream" {
            for x in self._walk(seed, depth, False) {
                hit.add(x);
            }
        } else {
            raise ValueError(direction);
        }
        out = set(hit);
        out.add(obj_name);
        for t in hit {  # columns ride along with every affected table
            for c in [self.objs[t] ->:Contains:->] {
                out.add(c.name);
            }
        }
        return sorted(out);
    }

    def counts_by_kind(names: list[str]) -> dict {
        counts: dict = {"table": 0, "column": 0};
        for n in names {
            counts[self.objs[n].kind] += 1;
        }
        return counts;
    }
}
