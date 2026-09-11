"""Guard: ZanattaMichael/Dsc.PipelineRunner#6."""

obj ConfigStore { has entries: dict[str, ConfigEntry] = {}; }

node ConfigEntry {
    has key: str;
    has raw: str;
}

edge RefTo {}

class CircularReferenceError(ValueError) {}

def load_config(entries: list[tuple[str, str]]) -> ConfigStore {
    cfg = ConfigStore();
    for (key, raw) in entries {
        e = ConfigEntry(key=key, raw=raw);
        root ++> e;
        cfg.entries[key] = e;
    }
    for e in cfg.entries.values() {
        raw = e.raw;
        if raw.startswith("[ref:") and raw.endswith("]") {
            tgt = raw[5:-1];
            dst = cfg.entries.get(tgt, None);
            if dst is not None { e +>:RefTo:+> dst; }
        }
    }
    return cfg;
}

walker ResolveWalk {
    has path: dict[str, bool] = {};
    has result: str = "";
    has cyclic: bool = False;
    has cycle_key: str = "";

    can step with ConfigEntry entry {
        if here.key in self.path {
            self.cyclic = True;
            self.cycle_key = here.key;
            skip;
        }
        self.path[here.key] = True;
        if not (here.raw.startswith("[ref:") and here.raw.endswith("]")) {
            self.result = here.raw;
            disengage;
        }
        targets = [here ->:RefTo:->][?:ConfigEntry];
        if targets { visit [targets[0]]; }
    }
}

def expand_references(cfg: ConfigStore) -> dict[str, str] {
    out: dict[str, str] = {};
    for key in sorted(cfg.entries.keys()) {
        e = cfg.entries[key];
        w = e spawn ResolveWalk(path={}, result="", cyclic=False, cycle_key="");
        if w.cyclic {
            raise CircularReferenceError(f"circular reference involving {w.cycle_key}");
        }
        out[key] = w.result if w.result else e.raw;
    }
    return out;
}

walker ChainWalk {
    has path: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with ConfigEntry entry {
        if here.key in self.path { skip; }
        self.path[here.key] = True;
        self.chain.append(here.key);
        if not (here.raw.startswith("[ref:") and here.raw.endswith("]")) { disengage; }
        targets = [here ->:RefTo:->][?:ConfigEntry];
        if targets { visit [targets[0]]; }
    }
}

def reference_chain(cfg: ConfigStore, key: str) -> list[str] {
    e = cfg.entries.get(key, None);
    if e is None { return []; }
    w = e spawn ChainWalk(path={}, chain=[]);
    return w.chain;
}

test "two-node cycle raises descriptive error" {
    cfg = load_config([("A", "[ref:B]"), ("B", "[ref:A]")]);
    raised = False;
    try { expand_references(cfg); }
    except CircularReferenceError { raised = True; }
    assert raised;
}

test "deep chain resolves without false cycle on diamond" {
    cfg = load_config(
        [("A", "[ref:B]"), ("B", "[ref:D]"), ("C", "[ref:D]"), ("D", "ok")],
    );
    assert expand_references(cfg) == {"A": "ok", "B": "ok", "C": "ok", "D": "ok"};
    assert reference_chain(cfg, "A") == ["A", "B", "D"];
}

test "plain entries pass through" {
    cfg = load_config([("X", "plain")]);
    assert expand_references(cfg) == {"X": "plain"};
}
