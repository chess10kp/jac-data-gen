"""Guard: leynos/ortho-config#439."""

node ConfigNode { has name: str; has keys: list[str] = []; }
edge Extends {}

obj ConfigStore {
    has configs: dict[str, ConfigNode] = {};

    def add_config(name: str, keys: list[str], parent: str | None = None) {
        if parent is not None and self.configs.get(parent, None) is None {
            raise KeyError("unknown parent config");
        }
        n = ConfigNode(name=name, keys=keys);
        root ++> n;
        self.configs[name] = n;
        if parent is not None {
            p = self.configs.get(parent, None);
            if p is not None { p +>:Extends:+> n; }
        }
    }

    def resolve_layers(name: str, max_depth: int) -> list[str] {
        start = self.configs.get(name, None);
        if start is None { raise KeyError("unknown config"); }
        w = start spawn AncestorAscent(active={}, chain=[], max_depth=max_depth);
        layers = [name] + w.chain;
        layers.reverse();
        return layers;
    }

    def flatten_keys(name: str, max_depth: int) -> list[str] {
        layers = self.resolve_layers(name, max_depth);
        seen: dict[str, bool] = {};
        out: list[str] = [];
        for layer in layers {
            cfg = self.configs.get(layer, None);
            if cfg is None { continue; }
            for k in cfg.keys {
                if k not in seen {
                    seen[k] = True;
                    out.append(k);
                }
            }
        }
        return out;
    }

    def descendant_configs(name: str) -> list[str] {
        start = self.configs.get(name, None);
        if start is None { raise KeyError("unknown config"); }
        w = start spawn DescendantWalk(claimed={}, found=[]);
        return sorted(w.found);
    }
}

class CycleError(Exception) {}
class DepthError(Exception) {}

walker AncestorAscent {
    has active: dict[str, bool];
    has max_depth: int;
    has chain: list[str] = [];
    has depth: int = 0;

    can step with ConfigNode entry {
        parents = [here <-:Extends:<-][?:ConfigNode];
        if len(parents) == 0 { disengage; }
        p = parents[0];
        if p.name in self.active { raise CycleError("extends cycle"); }
        self.active[p.name] = True;
        self.chain.append(p.name);
        self.depth += 1;
        if self.depth > self.max_depth { raise DepthError("extends depth exceeded"); }
        visit [p];
    }
}

walker DescendantWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with ConfigNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        visit [->:Extends:->] else { disengage; };
    }
}

test "inheritance layers and flatten" {
    st = ConfigStore();
    st.add_config("base", ["host", "port"]);
    st.add_config("app", ["name"], parent="base");
    st.add_config("env", ["debug"], parent="app");
    assert st.resolve_layers("env", max_depth=5) == ["base", "app", "env"];
    assert st.flatten_keys("env", max_depth=5) == ["host", "port", "name", "debug"];
    assert st.descendant_configs("base") == ["app", "base", "env"];
}

test "extends cycle raises" {
    st = ConfigStore();
    st.add_config("a", [], parent=None);
    st.add_config("b", [], parent="a");
    st.configs["a"];
    b = st.configs["b"];
    a = st.configs["a"];
    a +>:Extends:+> b;
    b +>:Extends:+> a;
    try {
        st.resolve_layers("a", max_depth=10);
        assert False;
    } except CycleError {
        assert True;
    }
}

test "depth budget exceeded" {
    st = ConfigStore();
    for i in range(6) {
        parent = ("c%d" % (i - 1)) if i > 0 else None;
        st.add_config("c%d" % i, ["k%d" % i], parent=parent);
    }
    try {
        st.resolve_layers("c5", max_depth=3);
        assert False;
    } except DepthError {
        assert True;
    }
}

test "unknown config raises" {
    st = ConfigStore();
    try {
        st.resolve_layers("ghost", max_depth=1);
        assert False;
    } except KeyError {
        assert True;
    }
}
