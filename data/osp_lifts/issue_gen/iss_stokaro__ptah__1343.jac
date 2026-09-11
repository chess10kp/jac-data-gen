"""stokaro/ptah#1343 — Canonical schema state and migration-order planning (OSP lift)."""

node SchemaObj {
    has name: str;
    has kind: str;
}

edge ChildOf {}
edge DependsOn {}

walker ParentChainWalker {
    has chain: list[str] = [];
    has seen: dict[str, bool] = {};

    can step with SchemaObj entry {
        parents = [here <-:ChildOf:<-][?:SchemaObj];
        if len(parents) == 0 {
            disengage;
        }
        par = parents[0];
        if par.name in self.seen {
            disengage;
        }
        self.seen[par.name] = True;
        self.chain.append(par.name);
        visit [par];
    }
}

walker TransitiveDepsWalker {
    has claimed: dict[str, bool] = {};
    has acc: list[str] = [];

    can step with SchemaObj entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.acc.append(here.name);
        visit [here <-:DependsOn:<-][?:SchemaObj] else {
            disengage;
        };
    }
}

walker MigrationTopo {
    has indegree: dict[str, int];
    has order: list[str] = [];
    has placed: dict[str, bool] = {};

    can schedule with Root entry {
        total = 0;
        for _m in [-->][?:SchemaObj] {
            total += 1;
        }
        while len(self.order) < total {
            ready: list[SchemaObj] = [];
            for m in [-->][?:SchemaObj] {
                if m.name in self.placed {
                    continue;
                }
                if self.indegree.get(m.name, 0) == 0 {
                    ready.append(m);
                }
            }
            if not ready {
                break;
            }
            best = ready[0];
            for cand in ready {
                if cand.name < best.name {
                    best = cand;
                }
            }
            self.placed[best.name] = True;
            visit [best];
        }
    }

    can emit with SchemaObj entry {
        self.order.append(here.name);
        for child in [here ->:DependsOn:->][?:SchemaObj] {
            nm = child.name;
            self.indegree[nm] = self.indegree.get(nm, 0) - 1;
        }
    }
}

obj SchemaState {
    has objs: dict[str, SchemaObj] = {};

    def add_object(name: str, kind: str, parent: str | None = None) -> None {
        if name in self.objs {
            raise ValueError("duplicate");
        }
        if parent is not None and parent not in self.objs {
            raise KeyError("unknown parent");
        }
        n = SchemaObj(name=name, kind=kind);
        root ++> n;
        self.objs[name] = n;
        if parent is not None {
            self.objs[parent] +>:ChildOf:+> n;
        }
    }

    def add_dependency(dependent: str, referenced: str) -> None {
        dep = self.objs.get(dependent, None);
        ref = self.objs.get(referenced, None);
        if dep is None or ref is None {
            raise KeyError("unknown object");
        }
        ref +>:DependsOn:+> dep;
    }

    def parent_chain(name: str) -> list[str] {
        if name not in self.objs {
            return [];
        }
        w = self.objs[name] spawn ParentChainWalker();
        return w.chain;
    }

    def dependencies_of(name: str) -> list[str] {
        if name not in self.objs {
            return [];
        }
        obj = self.objs[name];
        return sorted([u.name for u in [obj <-:DependsOn:<-][?:SchemaObj]]);
    }

    def transitive_dependencies(name: str) -> list[str] {
        if name not in self.objs {
            return [];
        }
        w = self.objs[name] spawn TransitiveDepsWalker();
        filtered = [x for x in w.acc if x != name];
        return sorted(filtered);
    }

    def migration_order() -> list[str] | None {
        indeg: dict[str, int] = {};
        for m in [-->][?:SchemaObj] {
            indeg[m.name] = len([m <-:DependsOn:<-][?:SchemaObj]);
        }
        w = root spawn MigrationTopo(indegree=indeg);
        if len(w.order) != len(indeg) {
            return None;
        }
        return w.order;
    }
}
