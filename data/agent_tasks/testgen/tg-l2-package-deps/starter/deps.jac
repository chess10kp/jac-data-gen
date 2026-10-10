"""Package dependency graph: transitive closure and install ordering."""

node Package {
    has name: str;
    has version: str = "0.0.0";
}

edge DependsOn: Package --> Package {}

walker Collect {
    """Visit every package reachable over DependsOn exactly once."""
    has seen: list[str] = [];
    has pkgs: list[Package] = [];

    can gather with Package entry {
        if here.name in self.seen {
            skip;
        }
        self.seen.append(here.name);
        self.pkgs.append(here);
        visit [here ->:DependsOn:->];
    }
}

walker TransitiveDeps(Collect) {
    can finish with exit {
        report sorted([p.name for p in self.pkgs[1:]]);
    }
}

walker InstallOrder(Collect) {
    can finish with exit {
        # Kahn's algorithm over the collected subgraph, dependencies first.
        remaining: dict[str, int] = {};
        for p in self.pkgs {
            remaining[p.name] = len([d for d in [p ->:DependsOn:->]]);
        }
        dependents: dict[str, list[str]] = {p.name: [] for p in self.pkgs};
        for p in self.pkgs {
            for d in [p ->:DependsOn:->] {
                dependents[d.name].append(p.name);
            }
        }
        ready = sorted([n for (n, k) in remaining.items() if k == 0]);
        order: list[str] = [];
        while ready {
            n = ready.pop(0);
            order.append(n);
            for m in dependents[n] {
                remaining[m] -= 1;
                if remaining[m] == 0 {
                    ready.append(m);
                }
            }
        }
        if len(order) != len(self.pkgs) {
            report "CYCLE";
        } else {
            report order;
        }
    }
}
