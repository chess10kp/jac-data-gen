"""WillSmithTE/intlayer#1 — entrypoint dependency reachability for runtime/dev separation."""

class IntlayerGraphError(Exception) {}

glob VALID_LAYERS = {"runtime", "server", "dev", "cli"};

node EntryAnchor {}

node Entry {
    has entry_id: str;
    has layer: str;
    has weight_kb: int;
}

edge EntryLink: Entry --> Entry {}

def sort_entries(items: list[Entry]) -> list[Entry] {
    names: list[str] = [];
    for it in items { names.append(it.entry_id); }
    names = sorted(names);
    out: list[Entry] = [];
    for nm in names {
        for it in items {
            if it.entry_id == nm { out.append(it); }
        }
    }
    return out;
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];

    can go with Entry entry {
        if here.entry_id in self.claimed { skip; }
        self.claimed[here.entry_id] = True;
        self.names.append(here.entry_id);
        kids = sort_entries([here ->:EntryLink:->]);
        for kid in kids { visit [kid]; }
    }
}

obj EntrypointGraph {
    has anchor: EntryAnchor;

    def init {
        self.anchor = EntryAnchor();
        root ++> self.anchor;
    }

    def _find(entry_id: str) -> Entry | None {
        for nd in [self.anchor -->][?:Entry] {
            if nd.entry_id == entry_id { return nd; }
        }
        return None;
    }

    def register(entry_id: str, layer: str, weight_kb: int) {
        if layer not in VALID_LAYERS { raise IntlayerGraphError("invalid layer"); }
        existing = self._find(entry_id);
        if existing is not None {
            existing.layer = layer;
            existing.weight_kb = weight_kb;
            return;
        }
        nd = Entry(entry_id=entry_id, layer=layer, weight_kb=weight_kb);
        self.anchor ++> nd;
    }

    def link(source: str, target: str) {
        src = self._find(source);
        dst = self._find(target);
        if src is None or dst is None { raise IntlayerGraphError("unknown entry"); }
        dup = False;
        for ex in [src ->:EntryLink:->] {
            if ex.entry_id == target { dup = True; }
        }
        if not dup { src +>:EntryLink():+> dst; }
    }

    def reachable_modules(root_id: str) -> list[str] {
        rt = self._find(root_id);
        if rt is None { raise IntlayerGraphError("unknown entry"); }
        w = rt spawn ReachWalk(claimed={}, names=[]);
        return sorted(w.names);
    }

    def reachable_weight_kb(root_id: str) -> int {
        mods = self.reachable_modules(root_id);
        total = 0;
        for mid in mods {
            nd = self._find(mid);
            if nd is not None { total += nd.weight_kb; }
        }
        return total;
    }

    def dev_leakage(root_id: str) -> list[str] {
        leaked: list[str] = [];
        for mid in self.reachable_modules(root_id) {
            nd = self._find(mid);
            if nd is not None and (nd.layer == "dev" or nd.layer == "cli") {
                leaked.append(mid);
            }
        }
        return sorted(leaked);
    }

    def separation_report(roots: list[str]) -> dict {
        out_map: dict = {};
        for root_id in sorted(roots) {
            if self._find(root_id) is None { raise IntlayerGraphError("unknown entry"); }
            out_map[root_id] = (self.reachable_weight_kb(root_id), self.dev_leakage(root_id));
        }
        return out_map;
    }

    def would_isolate(root_id: str, cut_edges: list[tuple[str, str]]) -> int {
        saved: list[tuple[Entry, Entry]] = [];
        for pair in cut_edges {
            src = self._find(pair[0]);
            dst = self._find(pair[1]);
            if src is None or dst is None { continue; }
            outs = [src ->:EntryLink:->];
            edges = [edge src ->:EntryLink:->];
            for i in range(len(outs)) {
                if outs[i].entry_id == dst.entry_id {
                    saved.append((src, dst));
                    del edges[i];
                    break;
                }
            }
        }
        weight = self.reachable_weight_kb(root_id);
        for pair in saved {
            pair[0] +>:EntryLink():+> pair[1];
        }
        return weight;
    }
}

test "diamond reachable_modules dedups convergent sink with adversarial edge order" {
    g = EntrypointGraph();
    g.register("root", "runtime", 1);
    g.register("left", "runtime", 2);
    g.register("right", "runtime", 3);
    g.register("sink", "dev", 4);
    g.link("root", "right");
    g.link("root", "left");
    g.link("right", "sink");
    g.link("left", "sink");
    assert g.reachable_modules("root") == ["left", "right", "root", "sink"];
}

test "dev_leakage includes cli layer modules" {
    g = EntrypointGraph();
    g.register("runtime-root", "runtime", 10);
    g.register("cli-tool", "cli", 50);
    g.link("runtime-root", "cli-tool");
    assert g.dev_leakage("runtime-root") == ["cli-tool"];
}

test "separation_report unknown root raises" {
    g = EntrypointGraph();
    g.register("only", "runtime", 1);
    raised = False;
    try {
        g.separation_report(["only", "ghost"]);
        assert False, "should have raised";
    } except IntlayerGraphError {
        raised = True;
    }
    assert raised;
}

test "would_isolate ignores unknown cut edges" {
    g = EntrypointGraph();
    g.register("runtime-root", "runtime", 8);
    g.register("server-bridge", "server", 40);
    g.register("dev-tool", "dev", 600);
    g.link("runtime-root", "server-bridge");
    g.link("server-bridge", "dev-tool");
    full = g.reachable_weight_kb("runtime-root");
    cut = g.would_isolate(
        "runtime-root",
        [("missing", "dev-tool"), ("server-bridge", "dev-tool")],
    );
    assert full == 648;
    assert cut == 48;
}

test "would_isolate cutting plugin bridge drops shared server graph" {
    g = EntrypointGraph();
    g.register("next-intlayer/server", "server", 200);
    g.register("next-intlayer/dev", "dev", 900);
    g.register("intlayer/server", "server", 40);
    g.register("intlayer/dev", "dev", 600);
    g.link("next-intlayer/server", "next-intlayer/dev");
    g.link("next-intlayer/server", "intlayer/server");
    g.link("intlayer/server", "intlayer/dev");
    assert g.would_isolate("next-intlayer/server", [("next-intlayer/server", "intlayer/server")]) == 1100;
}

test "reachable_modules unknown root raises" {
    g = EntrypointGraph();
    g.register("only", "runtime", 1);
    raised = False;
    try {
        g.reachable_modules("ghost");
        assert False, "should have raised";
    } except IntlayerGraphError {
        raised = True;
    }
    assert raised;
}
