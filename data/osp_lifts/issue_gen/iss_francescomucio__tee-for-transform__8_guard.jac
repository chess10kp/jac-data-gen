"""dbt-style model selection with dependency resolution.

francescomucio/tee-for-transform#8 lifted to OSP: models become Model
archetypes; (model -> depends_on) refs become typed DependsOn edges plus a
mirrored DependentOf edge so both selection directions stay walker-native.
The bounded breadth-first frontier loops become budget-decrementing flood
walkers -- depth limiting stays semantic -- and circular dependencies
terminate through the walkers' claim maps.
"""
node Model {
    has name: str;
}
edge DependsOn {}
edge DependentOf {}

"""Handle holding both adjacency directions as typed edges."""
obj ModelGraph {
    has deps_graph: dict[str, Model];
    has dependents_graph: dict[str, Model];

    def resolve(name: str) -> Model | None {
        return self.deps_graph.get(name);
    }

    def resolve_dependent(name: str) -> Model | None {
        return self.dependents_graph.get(name);
    }
}

def build_model_graph(models: list[str], refs: list[tuple[str, str]]) -> ModelGraph {
    g = ModelGraph(deps_graph={}, dependents_graph={});
    for m in models {
        n = Model(name=m);
        root ++> n;
        g.deps_graph[m] = n;
        g.dependents_graph[m] = n;
    }
    for (model, dep) in refs {
        a = g.deps_graph.get(model);
        b = g.deps_graph.get(dep);
        if a is not None and b is not None {
            # a depends on b: edge points at the dependency.
            a +>:DependsOn:+> b;
            b +>:DependentOf:+> a;
        }
    }
    return g;
}

walker UpFlood {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start_name: str = "";
    has budget: int = 0;

    can step with Model entry {
        if here.name in self.claimed {
            skip;
        }
        if here.name != self.start_name {
            self.reached.append(here.name);
        }
        self.claimed[here.name] = True;
        if self.budget <= 0 {
            skip;
        }
        for nb in [here ->:DependsOn:->] {
            nb spawn UpFlood(claimed=self.claimed, reached=self.reached,
                             start_name=self.start_name, budget=self.budget - 1);
        }
    }
}

walker DownFlood {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start_name: str = "";
    has budget: int = 0;

    can step with Model entry {
        if here.name in self.claimed {
            skip;
        }
        if here.name != self.start_name {
            self.reached.append(here.name);
        }
        self.claimed[here.name] = True;
        if self.budget <= 0 {
            skip;
        }
        for nb in [here ->:DependentOf:->] {
            nb spawn DownFlood(claimed=self.claimed, reached=self.reached,
                               start_name=self.start_name, budget=self.budget - 1);
        }
    }
}

"""Split a dbt-style spec into (model_name, direction, depth hops).

``model+`` is one upstream hop per trailing ``+`` (or ``+N`` for N hops);
leading ``+`` marks downstream hops. Mixing both is ambiguous and raises.
"""
def parse_select(spec: str) -> tuple[str, str, int] {
    body = spec.strip();
    lead = 0;
    while len(body) > 0 and body[0] == "+" {
        lead += 1;
        body = body[1:];
    }
    trail = 0;
    while True {
        n = len(body);
        if n > 0 and body[n - 1] == "+" {
            trail += 1;
            body = body[:n - 1];
            continue;
        }
        k = n;
        while k > 0 and body[k - 1].isdigit() {
            k -= 1;
        }
        if k < n and k > 0 and body[k - 1] == "+" {
            trail += int(body[k:n]);
            body = body[:k - 1];
            continue;
        }
        break;
    }
    if lead > 0 and trail > 0 {
        raise ValueError("ambiguous spec: " + spec);
    }
    if trail > 0 {
        return (body.strip(), "upstream", trail);
    }
    if lead > 0 {
        return (body.strip(), "downstream", lead);
    }
    return (body.strip(), "exact", 0);
}

"""Models matched by one selection spec (sorted, incl. the anchor)."""
def select_models(g: ModelGraph, spec: str) -> list[str] {
    parsed = parse_select(spec);
    name = parsed[0];
    direction = parsed[1];
    hops = parsed[2];
    anchor = None;
    if direction == "upstream" {
        anchor = g.resolve(name);
    } else {
        anchor = g.resolve_dependent(name);
    }
    if anchor is None {
        return [];
    }
    w = None;
    if direction == "upstream" {
        w = anchor spawn UpFlood(start_name=name, budget=hops);
    } elif direction == "downstream" {
        w = anchor spawn DownFlood(start_name=name, budget=hops);
    } else {
        w = anchor spawn UpFlood(start_name=name, budget=-1);
    }
    out: list[str] = [name];
    for r in w.reached {
        found = False;
        for o in out {
            if o == r {
                found = True;
            }
        }
        if not found {
            out.append(r);
        }
    }
    return sorted(out);
}

"""Union over several selection specs (sorted); unknown anchors skip."""
def resolve_selection(g: ModelGraph, specs: list[str]) -> list[str] {
    claim: dict[str, bool] = {};
    for spec in specs {
        for m in select_models(g, spec) {
            claim[m] = True;
        }
    }
    return sorted(claim.keys());
}
