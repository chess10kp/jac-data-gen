# Lift: EffortlessMetrics/perl-lsp-swarm#7493
# Retire the legacy reparsing WorkspaceIndex; per-file semantic contributions
# are deterministic facts; cross-file lookup goes through ProjectModel edges.

node Symbol {
    has name: str;
    has kind: str;
    has uri: str;
}

node FileUnit {
    has uri: str;
    has gen: int = 0;
}

edge DependsOn {}
edge Defines {}

obj SemanticAnalyzer {
    # per-file, deterministic fact extraction over supplied identity+text
    has facts: dict[str, list[dict[str, str]]] = {};

    def analyze(self, uri: str, gen: int, text: str) -> list[dict[str, str]] {
        syms: list[dict[str, str]] = [];
        for ln in text.split("\n") {
            parts: list[str] = ln.split(" ");
            if len(parts) > 1 and parts[0] == "sub" {
                s: dict[str, str] = {"name": parts[1], "kind": "sub", "uri": uri, "gen": str(gen)};
                syms.append(s);
            } elif len(parts) > 1 and parts[0] == "use" {
                s2: dict[str, str] = {"name": parts[1], "kind": "dep", "uri": uri, "gen": str(gen)};
                syms.append(s2);
            }
        }
        self.facts[uri] = syms;
        return syms;
    }

    def stale_check(self, uri: str, gen: int) -> bool {
        # stale generations cannot publish through a legacy cache
        if uri not in self.facts {
            return True;
        }
        for f in self.facts[uri] {
            if int(f["gen"]) != gen {
                return True;
            }
        }
        return False;
    }
}

def extract_names(facts: list[dict[str, str]]) -> list[str] {
    ns: list[str] = [];
    for f in facts {
        ns.append(f["name"]);
    }
    return sorted(ns);
}

obj ProjectModel {
    # owns cross-file materialization: files as nodes, deps as edges
    has touched: dict[str, bool] = {};

    def ingest(self, uri: str, facts: list[dict[str, str]]) -> FileUnit {
        fu = FileUnit(uri=uri);
        root ++> fu;
        for f in facts {
            if f["kind"] == "sub" {
                sn = Symbol(name=f["name"], kind="sub", uri=uri);
                fu +>:Defines:+> sn;
            } elif f["kind"] == "dep" {
                dn = Symbol(name=f["name"], kind="dep", uri=uri);
                fu +>:DependsOn:+> dn;
            }
        }
        self.touched[uri] = True;
        return fu;
    }

    def link(self, a: FileUnit, b: FileUnit) {
        a +>:DependsOn:+> b;
    }

    def deps_of(self, uri: str) -> list[str] {
        target: FileUnit | None = None;
        for c in root --> {
            fu = c as FileUnit;
            if fu.uri == uri {
                target = fu;
            }
        }
        found: list[str] = [];
        if target is None {
            return found;
        }
        for d in target -->:DependsOn:-> {
            ds = d as Symbol;
            if ds.kind == "dep" {
                found.append(ds.name);
            }
        }
        return sorted(found);
    }
}

walker CollectClosure {
    # cross-file lookup walk over ProjectModel graph; claim-map cycle policy
    has claimed: dict[str, bool] = {};
    has seen: list[str] = [];

    can step with FileUnit entry {
        if here.uri in self.claimed {
            skip;
        }
        self.claimed[here.uri] = True;
        self.seen.append(here.uri);
        nxt: list[FileUnit] = [];
        for ch in [here ->:DependsOn:->] {
            fs = ch as FileUnit | None;
            if fs is not None {
                nxt.append(fs);
            }
        }
        visit nxt;
    }

    can note_sym with Symbol entry {
        print("sym", here.name);
    }
}

walker IndexSymbols {
    # replaces legacy WorkspaceIndex: per-file symbol materialization
    has count: int = 0;

    can step with FileUnit entry {
        for ch in [here ->:Defines:->] {
            self.count += 1;
        }
        print("file", here.uri, "count", self.count);
    }
}
