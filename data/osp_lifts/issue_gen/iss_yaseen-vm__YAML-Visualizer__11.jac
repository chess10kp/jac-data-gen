"""yaseen-vm/YAML-Visualizer#11 — circular dependency detection (OSP lift)."""

obj ServiceGraph { has services: dict[str, Service] = {}; }

node Service {
    has sid: str;
    has depends: list[str] = [];
}

edge DependsOn {}

def load_services(
    services: list[str],
    depends_on: list[tuple[str, str]],
) -> ServiceGraph {
    g = ServiceGraph();
    for sid in services {
        if sid not in g.services {
            s = Service(sid=sid);
            root ++> s;
            g.services[sid] = s;
        }
    }
    for (src, dep) in depends_on {
        s: Service | None = g.services.get(src, None);
        if s is not None {
            s.depends = s.depends + [dep];
            t: Service | None = g.services.get(dep, None);
            if t is not None { s +>:DependsOn:+> t; }
        }
    }
    return g;
}

def missing_deps(g: ServiceGraph) -> list[str] {
    missing: set[str] = set();
    for sid in sorted(g.services.keys()) {
        svc = g.services[sid];
        for dep in svc.depends {
            if dep not in g.services { missing.add(dep); }
        }
    }
    return sorted(missing);
}

walker CycleProbe {
    has claimed: dict[str, bool] = {};
    has on_stack: dict[str, bool] = {};
    has found: bool = False;

    can step with Service entry {
        if self.found { disengage; }
        if here.sid in self.on_stack {
            self.found = True;
            disengage;
        }
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.on_stack[here.sid] = True;
        visit [->:DependsOn:->] else {
            del self.on_stack[here.sid];
            disengage;
        };
    }
}

def find_cycles(g: ServiceGraph) -> list[list[str]] {
    _ = g;
    return [];
}

def has_cycle(g: ServiceGraph) -> bool {
    for sid in sorted(g.services.keys()) {
        w = g.services[sid] spawn CycleProbe(claimed={}, on_stack={}, found=False);
        if w.found { return True; }
    }
    return False;
}
