node ElfObject {
    has path: str;
    has rpath: list[str] = [];
    has runpath: list[str] = [];
}
edge DepEdge {
    has dep_name: str = "";
}
node GraphRoot {
    has label: str = "root";
    has objects: dict[str, ElfObject] = {};
    has dep_names: dict[str, str] = {};
}
walker ClosureWalker {
    has entry_path: str = "";
    has inherited: list[str] = [];
    has claim: dict[str, bool] = {};
    has findings: list[dict[str, str]] = [];
    has graph_root: GraphRoot = GraphRoot();
    can traverse with ElfObject entry {
        inh_key: str = "";
        for p in self.inherited {
            if len(inh_key) > 0 {
                inh_key += ",";
            }
            inh_key += p;
        }
        claim_key: str = here.path + "|" + self.entry_path + "|" + inh_key;
        if claim_key in self.claim {
            skip;
        }
        self.claim[claim_key] = True;
        print("closure visit " + here.path + " entry=" + self.entry_path);
        new_inherited: list[str] = [];
        for p in self.inherited {
            new_inherited.append(p);
        }
        if len(here.runpath) == 0 {
            for p in here.rpath {
                new_inherited.append(p);
            }
        }
        kids: list[ElfObject] = [];
        for tgt in [here ->:DepEdge:->][?:ElfObject] {
            kids.append(tgt);
        }
        for kid in kids {
            lookup_key: str = here.path + "->" + kid.path;
            dep: str = "";
            if lookup_key in self.graph_root.dep_names {
                dep = self.graph_root.dep_names[lookup_key] as str;
            } else {
                parts: list[str] = kid.path.split("/");
                dep = parts[len(parts) - 1];
            }
            rec: dict[str, str] = {};
            rec["entry"] = self.entry_path;
            rec["consumer"] = here.path;
            rec["dep"] = dep;
            rec["provider"] = kid.path;
            rec["inherited"] = inh_key;
            self.findings.append(rec);
        }
        for kid in kids {
            cw: ClosureWalker = kid spawn ClosureWalker(entry_path=self.entry_path, inherited=new_inherited, claim=self.claim, graph_root=self.graph_root, findings=[]);
            for rec in cw.findings {
                self.findings.append(rec);
            }
            for k in cw.claim {
                self.claim[k] = True;
            }
        }
    }
}
def new_graph() -> GraphRoot {
    g: GraphRoot = GraphRoot();
    return g;
}
def add_object(graph_root: GraphRoot, path: str, rpath: list[str] | None = None, runpath: list[str] | None = None) -> ElfObject {
    r: list[str] = [];
    if rpath != None {
        r = rpath as list[str];
    }
    ru: list[str] = [];
    if runpath != None {
        ru = runpath as list[str];
    }
    nd: ElfObject = ElfObject(path=path, rpath=r, runpath=ru);
    graph_root.objects[path] = nd;
    graph_root ++> nd;
    return nd;
}
def add_dependency(graph_root: GraphRoot, consumer_path: str, dep_name: str, provider_path: str) -> None {
    if consumer_path not in graph_root.objects {
        return;
    }
    if provider_path not in graph_root.objects {
        return;
    }
    cons: ElfObject = graph_root.objects[consumer_path] as ElfObject;
    prov: ElfObject = graph_root.objects[provider_path] as ElfObject;
    cons +>:DepEdge(dep_name=dep_name):+> prov;
    key: str = consumer_path + "->" + provider_path;
    graph_root.dep_names[key] = dep_name;
}
def analyze_closure(graph_root: GraphRoot, entry_paths: list[str]) -> list[dict[str, str]] {
    all_findings: list[dict[str, str]] = [];
    shared_claim: dict[str, bool] = {};
    for ep in entry_paths {
        if ep in graph_root.objects {
            nd: ElfObject = graph_root.objects[ep] as ElfObject;
            w: ClosureWalker = nd spawn ClosureWalker(entry_path=ep, inherited=[], claim=shared_claim, graph_root=graph_root, findings=[]);
            for rec in w.findings {
                all_findings.append(rec);
            }
            for k in w.claim {
                shared_claim[k] = True;
            }
        }
    }
    n: int = len(all_findings);
    for i in range(n) {
        for j in range(n) {
            if j <= i {
                continue;
            }
            a: dict[str, str] = all_findings[i];
            b: dict[str, str] = all_findings[j];
            ka: str = a["entry"] + "|" + a["consumer"] + "|" + a["dep"] + "|" + a["provider"];
            kb: str = b["entry"] + "|" + b["consumer"] + "|" + b["dep"] + "|" + b["provider"];
            if ka > kb {
                tmp: dict[str, str] = all_findings[i];
                all_findings[i] = all_findings[j];
                all_findings[j] = tmp;
            }
        }
    }
    return all_findings;
}
def run_closure(graph_root: GraphRoot, entry_paths: list[str]) -> list[dict[str, str]] {
    return analyze_closure(graph_root, entry_paths);
}
def closure_analyze(graph_root: GraphRoot, entry_paths: list[str]) -> list[dict[str, str]] {
    return analyze_closure(graph_root, entry_paths);
}
