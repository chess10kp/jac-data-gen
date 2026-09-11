"""Typed upgrade patches: semantic frontier. kofun-lang/kofun#885."""

node Field { has name: str; }
edge DependsOn {}

obj SchemaGraph { has stamp: int = 0; }

walker AncestorWalk {
    has start: str;
    has chain: list[str] = [];
    has reports: list[list[str]] = [];

    can begin with Root entry {
        for f in [-->][?:Field] {
            if f.name == self.start {
                visit [f];
            }
        }
    }

    can step with Field entry {
        parents = [here ->:DependsOn:->];
        if len(parents) > 0 {
            self.chain.append(parents[0].name);
            visit [parents[0]];
        }
    }

    can finish with Root exit { report self.chain; }
}

walker FrontierWalk {
    has seeds: list[str] = [];
    has claimed: dict[str, bool] = {};
    has frontier: list[str] = [];
    has reports: list[list[str]] = [];

    can begin with Root entry {
        for f in [-->][?:Field] {
            for s in self.seeds {
                if f.name == s {
                    visit [f];
                }
            }
        }
    }

    can step with Field entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        for dep in [here ->:DependsOn:->] {
            if dep.name not in self.claimed {
                self.frontier.append(dep.name);
            }
            visit [dep];
        }
    }

    can finish with Root exit { report sorted(self.frontier); }
}

def build_schema_graph(fields: list[str], depends: list[tuple[str, str]]) -> SchemaGraph {
    nodes: dict[str, Field] = {};
    for f in fields {
        n = Field(name=f);
        root ++> n;
        nodes[f] = n;
    }
    for (child, parent) in depends {
        nodes[child] +>:DependsOn:+> nodes[parent];
    }
    return SchemaGraph(stamp=1);
}

def ancestors(graph: SchemaGraph, field: str) -> list[str] {
    _ = graph;
    w = root spawn AncestorWalk(start=field);
    return w.reports[0] if w.reports else [];
}

def semantic_frontier(graph: SchemaGraph, changed: list[str]) -> list[str] {
    _ = graph;
    w = root spawn FrontierWalk(seeds=changed);
    return w.reports[0] if w.reports else [];
}
