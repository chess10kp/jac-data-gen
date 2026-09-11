"""ZanattaMichael/Dsc.PipelineRunner#6 — circular-reference detection with backtracking path set."""
import from __future__ { annotations }
class ConfigStore {
    def init(self: ConfigStore) -> None {
        self._values: dict[(str, str)] = {};
    }
}
def load_config(entries: list[tuple[(str, str)]]) -> ConfigStore {
    cfg = ConfigStore();
    for (key, raw) in entries {
        cfg._values[key] = raw;
    }
    return cfg;
}
class CircularReferenceError(ValueError) {}
def _resolve_key(cfg: ConfigStore, key: str, path: set[str]) -> str {
    if (key not in cfg._values) {
        raise KeyError(key);
    }
    if (key in path) {
        raise CircularReferenceError(f"circular reference involving {key}");
    }
    raw = cfg._values[key];
    if not (raw.startswith("[ref:") and raw.endswith("]")) {
        return raw;
    }
    target = raw[5:-1];
    path.add(key);
    try {
        out = _resolve_key(cfg, target, path);
    } finally {
        path.remove(key);
    }
    return out;
}
def expand_references(cfg: ConfigStore) -> dict[(str, str)] {
    out: dict[(str, str)] = {};
    for key in sorted(cfg._values) {
        out[key] = _resolve_key(cfg, key, `set());
    }
    return out;
}
def reference_chain(cfg: ConfigStore, key: str) -> list[str] {
    if (key not in cfg._values) {
        return [];
    }
    chain = [key];
    path: set[str] = {key};
    raw = cfg._values[key];
    while (raw.startswith("[ref:") and raw.endswith("]")) {
        nxt = raw[5:-1];
        if ((nxt in path) or (nxt not in cfg._values)) {
            break;
        }
        path.add(nxt);
        chain.append(nxt);
        raw = cfg._values[nxt];
    }
    return chain;
}

