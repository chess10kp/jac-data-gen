# AgentsKit-io/doc-bridge#108 — ReconciliationReportV1 offline HTML reporter (OSP lift)
# Python before: adjacency dicts + BFS/DFS for upstream/downstream, dict scans for filters/search
node Report { has rid: str; has title: str; }
node Package { has pid: str; has name: str; }
node Module { has mid: str; has name: str; has path: str; }
node Evidence { has evid: str; has path: str; has start_line: int; has end_line: int; has hashv: str; has snippet: str = ""; }
node Diagnostic { has did: str; has severity: str; has provenance: str; has status: str; has analyzer: str; has entity_id: str; }

edge Contains {}
edge Depends {}
edge DependedBy {}
edge HasEvidence {}
edge HasDiagnostic {}

walker DownstreamCollect {
    has visited: dict[str, bool] = {};
    has collected: list[str] = [];
    can step with Module entry {
        if here.mid in self.visited { skip; }
        self.visited[here.mid] = True;
        self.collected.append(here.mid);
        print(here.mid);
        kids: list[Module] = [here ->:Depends:->][?:Module];
        for k in kids { visit :0: [k]; }
        if kids.len == 0 { disengage; }
    }
}

walker UpstreamCollect {
    has visited: dict[str, bool] = {};
    has collected: list[str] = [];
    can step with Module entry {
        if here.mid in self.visited { skip; }
        self.visited[here.mid] = True;
        self.collected.append(here.mid);
        print(here.mid);
        parents: list[Module] = [here ->:DependedBy:->][?:Module];
        for p in parents { visit :0: [p]; }
        if parents.len == 0 { disengage; }
    }
}

walker DiagAnchorWalk {
    has visited: dict[str, bool] = {};
    has anchors: list[str] = [];
    can step with Diagnostic entry {
        if here.did in self.visited { skip; }
        self.visited[here.did] = True;
        self.anchors.append(here.did);
        print(here.did);
        disengage;
    }
}

def create_report(rid: str, title: str) -> Report {
    rep = Report(rid=rid, title=title);
    root ++> rep;
    return rep;
}

def add_package(rep_root: Report, pid: str, name: str) -> Package {
    pkg = Package(pid=pid, name=name);
    rep_root +>:Contains:+> pkg;
    return pkg;
}

def add_module(pkg: Package, mid: str, name: str, path: str) -> Module {
    mod = Module(mid=mid, name=name, path=path);
    pkg +>:Contains:+> mod;
    return mod;
}

def add_dependency(from_mod: Module, to_mod: Module) -> None {
    from_mod +>:Depends:+> to_mod;
    to_mod +>:DependedBy:+> from_mod;
}

def add_evidence(rep_root: Report, evid: str, path: str, start_line: int, end_line: int, hashv: str) -> Evidence {
    ev = Evidence(evid=evid, path=path, start_line=start_line, end_line=end_line, hashv=hashv);
    rep_root +>:HasEvidence:+> ev;
    return ev;
}

def add_diagnostic(rep_root: Report, did: str, severity: str, provenance: str, status: str, analyzer: str, entity_id: str) -> Diagnostic {
    dg = Diagnostic(did=did, severity=severity, provenance=provenance, status=status, analyzer=analyzer, entity_id=entity_id);
    rep_root +>:HasDiagnostic:+> dg;
    return dg;
}

def get_downstream(start: Module) -> list[str] {
    w = start spawn DownstreamCollect(visited={}, collected=[]);
    out: list[str] = sorted(w.collected);
    return out;
}

def get_upstream(start: Module) -> list[str] {
    w = start spawn UpstreamCollect(visited={}, collected=[]);
    out: list[str] = sorted(w.collected);
    return out;
}

def filter_diagnostics(rep_root: Report, severity: str | None = None, analyzer: str | None = None) -> list[str] {
    res: list[str] = [];
    diags: list[Diagnostic] = [rep_root ->:HasDiagnostic:->][?:Diagnostic];
    for d in diags {
        if severity is not None {
            if d.severity != severity { continue; }
        }
        if analyzer is not None {
            if d.analyzer != analyzer { continue; }
        }
        res.append(d.did);
    }
    return sorted(res);
}

def search_entities(rep_root: Report, query: str) -> list[str] {
    hits: list[str] = [];
    pkgs: list[Package] = [rep_root ->:Contains:->][?:Package];
    for p in pkgs {
        if query in p.name { hits.append(p.pid); }
        mods: list[Module] = [p ->:Contains:->][?:Module];
        for m in mods {
            if query in m.name { hits.append(m.mid); }
            if query in m.path { hits.append(m.mid); }
        }
    }
    return sorted(hits);
}

def render_html(rep_root: Report, include_snippets: bool = False) -> str {
    # deterministic offline HTML; malformed artifacts render error page; snippets redacted unless opted-in
    if rep_root.rid == "" {
        return "<html><body><h1>Error: malformed report</h1><p>missing rid</p></body></html>";
    }
    pkgs: list[Package] = [rep_root ->:Contains:->][?:Package];
    diags: list[Diagnostic] = [rep_root ->:HasDiagnostic:->][?:Diagnostic];
    evs: list[Evidence] = [rep_root ->:HasEvidence:->][?:Evidence];
    pkg_ids: list[str] = [];
    for p in pkgs { pkg_ids.append(p.pid); }
    diag_ids: list[str] = [];
    for d in diags { diag_ids.append(d.did); }
    ev_ids: list[str] = [];
    for e in evs { ev_ids.append(e.evid); }
    pkg_ids = sorted(pkg_ids);
    diag_ids = sorted(diag_ids);
    ev_ids = sorted(ev_ids);
    html: str = "<html><head><style>offline</style></head><body>";
    html = html + "<h1 id='report-" + rep_root.rid + "'>" + rep_root.title + "</h1>";
    html = html + "<section id='arch'>";
    for pid in pkg_ids { html = html + "<div id='pkg-" + pid + "'></div>"; }
    html = html + "</section><section id='diagnostics'>";
    for did in diag_ids { html = html + "<div id='diag-" + did + "'></div>"; }
    html = html + "</section><section id='evidence'>";
    for e in evs {
        html = html + "<a id='ev-" + e.evid + "' href='" + e.path + "#" + str(e.start_line) + "-" + str(e.end_line) + "' data-hash='" + e.hashv + "'>";
        if include_snippets {
            html = html + e.snippet;
        }
        html = html + "</a>";
    }
    html = html + "</section></body></html>";
    return html;
}

with entry {
    demo_rep = Report(rid="demo", title="demo");
    root ++> demo_rep;
    w = demo_rep spawn DiagAnchorWalk(visited={}, anchors=[]);
    print("offline reporter demo ready");
}
