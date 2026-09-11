"""rrousselGit/riverpod#4839 — riverpod_lint sandbox dependency reachability."""

node Package {
    has cid: str;
    has label: str = "";
}

edge Depends {}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has start_cid: str = "";

    can step with Package entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("reach ", here.cid);
        if here.cid != self.start_cid {
            self.found.append(here.cid);
        }
        deps: list[Package] = [here ->:Depends:->][?:Package];
        for dep in deps {
            visit :0: [dep];
        }
    }
}

walker PathWalker {
    has claimed: dict[str, bool] = {};
    has end_cid: str = "";
    has hit: bool = False;

    can step with Package entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("reach ", here.cid);
        if here.cid == self.end_cid {
            self.hit = True;
        }
        deps: list[Package] = [here ->:Depends:->][?:Package];
        for dep in deps {
            visit :0: [dep];
        }
    }
}

def _index_packages(nodes: list[Package]) -> dict[str, Package] {
    idx: dict[str, Package] = {};
    for nd in nodes {
        idx[nd.cid] = nd;
    }
    return idx;
}

def make_sandbox_graph() -> list[Package] {
    lint = Package(cid="riverpod_lint", label="3.1.8");
    utils = Package(cid="riverpod_analyzer_utils", label="1.0.0-dev.11");
    plugin = Package(cid="analysis_server_plugin", label="0.3.18");
    analyzer = Package(cid="analyzer", label="13.3.0");
    lint +>:Depends:+> utils;
    utils +>:Depends:+> plugin;
    utils +>:Depends:+> analyzer;
    plugin +>:Depends:+> analyzer;
    analyzer +>:Depends:+> lint;
    root ++> lint;
    root ++> utils;
    root ++> plugin;
    root ++> analyzer;
    out: list[Package] = [lint, utils, plugin, analyzer];
    return out;
}

def make_diamond_graph() -> list[Package] {
    lint = Package(cid="riverpod_lint");
    utils = Package(cid="riverpod_analyzer_utils");
    analyzer = Package(cid="analyzer");
    plugin = Package(cid="analysis_server_plugin");
    lint +>:Depends:+> utils;
    lint +>:Depends:+> analyzer;
    utils +>:Depends:+> plugin;
    analyzer +>:Depends:+> plugin;
    root ++> lint;
    root ++> utils;
    root ++> analyzer;
    root ++> plugin;
    out: list[Package] = [lint, utils, analyzer, plugin];
    return out;
}

def reachable_sorted(start: str, nodes: list[Package]) -> list[str] {
    idx: dict[str, Package] = _index_packages(nodes);
    if start not in idx {
        return [];
    }
    w = idx[start] spawn ReachWalker(start_cid=start, claimed={}, found=[]);
    xs: list[str] = w.found;
    return sorted(xs);
}

def has_path(start: str, end: str, nodes: list[Package]) -> bool {
    idx: dict[str, Package] = _index_packages(nodes);
    if start not in idx {
        return False;
    }
    if end not in idx {
        return False;
    }
    w = idx[start] spawn PathWalker(end_cid=end, claimed={}, hit=False);
    return w.hit;
}

def sdk_handshake_hangs(sdk: str, lint_version: str) -> bool {
    if lint_version == "3.1.4" {
        return False;
    }
    if lint_version == "3.1.8" and sdk == "3.12.2" {
        return True;
    }
    return False;
}
