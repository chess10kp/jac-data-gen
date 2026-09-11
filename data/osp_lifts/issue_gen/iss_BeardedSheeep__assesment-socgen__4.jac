"""BeardedSheeep/assesment-socgen#4 — Docker layer rebuild dependency graph."""

node Layer {
    has name: str;
}

edge DependsOn {}

obj LayerGraph {
    has layers: dict[str, Layer] = {};
}

walker InvalidateWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Layer entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [<-:DependsOn:<-][?:Layer];
    }
}

def load_layers(layers: list[str], deps: list[tuple[str, str]]) -> LayerGraph {
    g = LayerGraph();
    for name in layers {
        nd = Layer(name=name);
        root ++> nd;
        g.layers[name] = nd;
    }
    for (base, upper) in deps {
        b = g.layers.get(base, None);
        u = g.layers.get(upper, None);
        if b is not None and u is not None { u +>:DependsOn:+> b; }
    }
    return g;
}

def invalidated_by(store: LayerGraph, changed: str) -> list[str] {
    nd = store.layers.get(changed, None);
    if nd is None { return []; }
    claimed: dict[str, bool] = {changed: True};
    snap: list[str] = [];
    for d in [nd <-:DependsOn:<-][?:Layer] {
        if d.name not in claimed {
            claimed[d.name] = True;
            snap.append(d.name);
        }
    }
    i = 0;
    while i < len(snap) {
        cur_name = snap[i];
        i += 1;
        cur = store.layers.get(cur_name, None);
        if cur is None { continue; }
        for d in [cur <-:DependsOn:<-][?:Layer] {
            if d.name not in claimed {
                claimed[d.name] = True;
                snap.append(d.name);
            }
        }
    }
    return sorted(snap);
}
