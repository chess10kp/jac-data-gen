"""Hand-rolled Cargo-style dependency graph audit helpers.

Issue: cryptnetworks/NexaChat#210
"""

glob _FIXTURE: list[tuple[str, list[str]]] = [
    ("nexa-desktop", ["tauri"]),
    ("tauri", ["gtk", "tauri-runtime-wry", "tauri-utils"]),
    ("gtk", ["glib"]),
    ("tauri-runtime-wry", ["wry"]),
    ("wry", ["tao", "webkit2gtk"]),
    ("webkit2gtk", ["gtk"]),
    ("tao", ["glib"]),
    ("tauri-utils", ["urlpattern"]),
    ("urlpattern", ["unic-ucd-version"]),
    ("unic-ucd-version", []),
    ("glib", []),
];

node Crate {
    has name: str;
}

edge Depends {}

walker TransitiveWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Crate entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin {
            self.found.append(here.name);
        }
        kids = [here ->:Depends:->][?:Crate];
        nms: list[str] = [];
        for n in kids { nms.append(n.name); }
        for nm in sorted(nms) {
            for n in kids {
                if n.name == nm {
                    n spawn TransitiveWalk(
                        claimed=self.claimed,
                        found=self.found,
                        origin=self.origin,
                    );
                }
            }
        }
    }
}

walker DepPathWalk {
    has target: str = "";
    has max_depth: int = 12;
    has trail: list[str] = [];
    has on_path: dict[str, bool] = {};
    has paths: list[list[str]] = [];

    can step with Crate entry {
        if here.name in self.on_path { skip; }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.name);
        nop: dict[str, bool] = {**self.on_path, here.name: True};
        if len(nt) > self.max_depth { skip; }
        if here.name == self.target {
            row: list[str] = [];
            for x in nt { row.append(x); }
            self.paths.append(row);
            skip;
        }
        if len(nt) >= self.max_depth { skip; }
        kids = [here ->:Depends:->][?:Crate];
        nms: list[str] = [];
        for n in kids { nms.append(n.name); }
        for nm in sorted(nms) {
            for n in kids {
                if n.name == nm {
                    n spawn DepPathWalk(
                        target=self.target,
                        max_depth=self.max_depth,
                        trail=nt,
                        on_path=nop,
                        paths=self.paths,
                    );
                }
            }
        }
    }
}

def _bootstrap() -> dict[str, Crate] {
    live = [root -->][?:Crate];
    if len(live) > 0 {
        units: dict[str, Crate] = {};
        for nd in live { units[nd.name] = nd; }
        return units;
    }
    units: dict[str, Crate] = {};
    names: dict[str, bool] = {};
    for (crate, deps) in _FIXTURE {
        names[crate] = True;
        for d in deps { names[d] = True; }
    }
    keys: list[str] = [];
    for nm in names { keys.append(nm); }
    for nm in sorted(keys) {
        nd = Crate(name=nm);
        root ++> nd;
        units[nm] = nd;
    }
    for (crate, deps) in _FIXTURE {
        parent = units[crate];
        for d in deps {
            parent +>:Depends:+> units[d];
        }
    }
    return units;
}

def _adv_id(rec: dict) -> str {
    return rec["id"];
}

def direct_dependencies(crate: str) -> list[str] {
    units = _bootstrap();
    nd = units.get(crate, None);
    if nd is None { return []; }
    return sorted([k.name for k in [nd ->:Depends:->][?:Crate]]);
}

def transitive_dependencies(`root: str) -> list[str] {
    units = _bootstrap();
    nd = units.get(`root, None);
    if nd is None { return []; }
    w = nd spawn TransitiveWalk(claimed={}, found=[], origin=`root);
    return sorted(w.found);
}

def dependency_paths(`root: str, target: str, max_depth: int = 12) -> list[list[str]] {
    units = _bootstrap();
    if `root not in units or target not in units { return []; }
    nd = units[`root];
    w = nd spawn DepPathWalk(
        target=target,
        max_depth=max_depth,
        trail=[],
        on_path={},
        paths=[],
    );
    out: list[list[str]] = [];
    for p in w.paths {
        row: list[str] = [];
        for x in p { row.append(x); }
        out.append(row);
    }
    return sorted(out);
}

def dedupe_advisory_aliases(records: list[dict]) -> list[dict] {
    groups: dict[tuple[str, ...], dict] = {};
    for rec in records {
        aliases = rec.get("aliases") or [rec["id"]];
        key = tuple(sorted(aliases));
        if key not in groups {
            groups[key] = rec;
        }
    }
    out: list[dict] = [];
    for rec in groups.values() { out.append(rec); }
    return sorted(out, key=_adv_id);
}

def unreviewed_vulnerability_ids(`root: str, advisories: list[dict]) -> list[str] {
    reachable: dict[str, bool] = {};
    for n in transitive_dependencies(`root) { reachable[n] = True; }
    reachable[`root] = True;
    blocked: list[str] = [];
    for adv in dedupe_advisory_aliases(advisories) {
        if adv.get("kind") != "vulnerability" { continue; }
        if reachable.get(adv["package"]) {
            blocked.append(adv["id"]);
        }
    }
    return sorted(blocked);
}
