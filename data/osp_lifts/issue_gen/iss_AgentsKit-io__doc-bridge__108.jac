node Report { has rid: str; has run_hash: str; }
node Package { has pid: str; has path: str; has provenance: str; }
node Module { has mid: str; has path: str; has provenance: str; }
node Relation { has rel_id: str; has kind: str; has src: str; has dst: str; }
node Diagnostic { has did: str; has severity: str; has status: str; has analyzer: str; has entity_ref: str; has relation_ref: str; }
node Evidence { has eid: str; has path: str; has line_start: int; has line_end: int; has hash_val: str; }
edge Contains {}
edge Depends {}
edge HasEvidence {}

walker UpstreamWalker {
    has claimed: dict[str, bool] = {};
    has result: list[str] = [];
    can up_mod with Module entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.result.append(here.mid);
        print(here.mid);
        for p in [here <-:Depends<-][?:Module] { visit :0: [p]; }
        for q in [here <-:Depends<-][?:Package] { visit :0: [q]; }
        visit [] else { disengage; }
    }
    can up_pkg with Package entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        self.result.append(here.pid);
        print(here.pid);
        for p in [here <-:Depends<-][?:Package] { visit :0: [p]; }
        for m in [here <-:Depends<-][?:Module] { visit :0: [m]; }
        visit [] else { disengage; }
    }
}
walker DownstreamWalker {
    has claimed: dict[str, bool] = {};
    has result: list[str] = [];
    can down_mod with Module entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.result.append(here.mid);
        print(here.mid);
        for c in [here ->:Depends:->][?:Module] { visit :0: [c]; }
        for d in [here ->:Depends:->][?:Package] { visit :0: [d]; }
        visit [] else { disengage; }
    }
    can down_pkg with Package entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        self.result.append(here.pid);
        print(here.pid);
        for c in [here ->:Depends:->][?:Package] { visit :0: [c]; }
        for d in [here ->:Depends:->][?:Module] { visit :0: [d]; }
        visit [] else { disengage; }
    }
}
walker CollectAllWalker {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];
    can c_report with Report entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        print(here.rid);
        for n in [here ->:Contains:->][?:Package] { visit :0: [n]; }
        for m in [here ->:Contains:->][?:Module] { visit :0: [m]; }
        for r in [here ->:Contains:->][?:Relation] { visit :0: [r]; }
        for d in [here ->:Contains:->][?:Diagnostic] { visit :0: [d]; }
        for e in [here ->:Contains:->][?:Evidence] { visit :0: [e]; }
        visit [] else { disengage; }
    }
    can c_pkg with Package entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        self.ids.append(here.pid);
        print(here.pid);
        visit [] else { disengage; }
    }
    can c_mod with Module entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.ids.append(here.mid);
        print(here.mid);
        visit [] else { disengage; }
    }
    can c_rel with Relation entry {
        if here.rel_id in self.claimed { skip; }
        self.claimed[here.rel_id] = True;
        self.ids.append(here.rel_id);
        print(here.rel_id);
        visit [] else { disengage; }
    }
    can c_diag with Diagnostic entry {
        if here.did in self.claimed { skip; }
        self.claimed[here.did] = True;
        self.ids.append(here.did);
        print(here.did);
        visit [] else { disengage; }
    }
    can c_evid with Evidence entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        self.ids.append(here.eid);
        print(here.eid);
        visit [] else { disengage; }
    }
}

def create_report(rid: str, run_hash: str) -> Report {
    rpt = Report(rid=rid, run_hash=run_hash);
    root ++> rpt;
    return rpt;
}
def add_package(rpt: Report, pid: str, path: str, provenance: str) -> Package {
    pkg = Package(pid=pid, path=path, provenance=provenance);
    rpt +>:Contains:+> pkg;
    return pkg;
}
def add_module(rpt: Report, pid: str, mid: str, path: str, provenance: str) -> Module {
    # find package by pid
    found: list[Package] = [rpt ->:Contains:->][?:Package];
    target: Package | None = None;
    for p in found { if p.pid == pid { target = p; } }
    mod = Module(mid=mid, path=path, provenance=provenance);
    rpt +>:Contains:+> mod;
    if target is not None { target +>:Contains:+> mod; }
    return mod;
}
def add_relation(rpt: Report, rel_id: str, kind: str, src: str, dst: str) -> Relation {
    rel = Relation(rel_id=rel_id, kind=kind, src=src, dst=dst);
    rpt +>:Contains:+> rel;
    # connect actual src/dst nodes if present for traversal
    pkgs: list[Package] = [rpt ->:Contains:->][?:Package];
    mods: list[Module] = [rpt ->:Contains:->][?:Module];
    src_node: Package | None = None;
    dst_node: Package | None = None;
    src_mod: Module | None = None;
    dst_mod: Module | None = None;
    for p in pkgs { if p.pid == src { src_node = p; } if p.pid == dst { dst_node = p; } }
    for m in mods { if m.mid == src { src_mod = m; } if m.mid == dst { dst_mod = m; } }
    if src_mod is not None { if dst_mod is not None { src_mod +>:Depends:+> dst_mod; } }
    if src_node is not None { if dst_node is not None { src_node +>:Depends:+> dst_node; } }
    if src_mod is not None { if dst_node is not None { src_mod +>:Depends:+> dst_node; } }
    if src_node is not None { if dst_mod is not None { src_node +>:Depends:+> dst_mod; } }
    return rel;
}
def add_diagnostic(rpt: Report, did: str, severity: str, status: str, analyzer: str, entity_ref: str, relation_ref: str) -> Diagnostic {
    diag = Diagnostic(did=did, severity=severity, status=status, analyzer=analyzer, entity_ref=entity_ref, relation_ref=relation_ref);
    rpt +>:Contains:+> diag;
    return diag;
}
def add_evidence(rpt: Report, eid: str, path: str, line_start: int, line_end: int, hash_val: str) -> Evidence {
    ev = Evidence(eid=eid, path=path, line_start=line_start, line_end=line_end, hash_val=hash_val);
    rpt +>:Contains:+> ev;
    return ev;
}
def link_evidence(rpt: Report, owner_id: str, eid: str) -> bool {
    diags: list[Diagnostic] = [rpt ->:Contains:->][?:Diagnostic];
    evs: list[Evidence] = [rpt ->:Contains:->][?:Evidence];
    rels: list[Relation] = [rpt ->:Contains:->][?:Relation];
    target_e: Evidence | None = None;
    for e in evs { if e.eid == eid { target_e = e; } }
    if target_e is None { return False; }
    for d in diags { if d.did == owner_id { d +>:HasEvidence:+> target_e; return True; } }
    for r in rels { if r.rel_id == owner_id { r +>:HasEvidence:+> target_e; return True; } }
    return False;
}
def find_node_any(rpt: Report, nid: str) -> bool {
    for p in [rpt ->:Contains:->][?:Package] { if p.pid == nid { return True; } }
    for m in [rpt ->:Contains:->][?:Module] { if m.mid == nid { return True; } }
    return False;
}
def get_upstream(rpt: Report, start_id: str) -> list[str] {
    # locate start node
    mods: list[Module] = [rpt ->:Contains:->][?:Module];
    pkgs: list[Package] = [rpt ->:Contains:->][?:Package];
    start_mod: Module | None = None;
    start_pkg: Package | None = None;
    for m in mods { if m.mid == start_id { start_mod = m; } }
    for p in pkgs { if p.pid == start_id { start_pkg = p; } }
    if start_mod is not None {
        w = start_mod spawn UpstreamWalker(claimed={}, result=[]);
        res: list[str] = sorted(w.result);
        return res;
    }
    if start_pkg is not None {
        w2 = start_pkg spawn UpstreamWalker(claimed={}, result=[]);
        res2: list[str] = sorted(w2.result);
        return res2;
    }
    return [];
}
def get_downstream(rpt: Report, start_id: str) -> list[str] {
    mods: list[Module] = [rpt ->:Contains:->][?:Module];
    pkgs: list[Package] = [rpt ->:Contains:->][?:Package];
    start_mod: Module | None = None;
    start_pkg: Package | None = None;
    for m in mods { if m.mid == start_id { start_mod = m; } }
    for p in pkgs { if p.pid == start_id { start_pkg = p; } }
    if start_mod is not None {
        w = start_mod spawn DownstreamWalker(claimed={}, result=[]);
        return sorted(w.result);
    }
    if start_pkg is not None {
        w2 = start_pkg spawn DownstreamWalker(claimed={}, result=[]);
        return sorted(w2.result);
    }
    return [];
}
def search_entities(rpt: Report, query: str) -> list[str] {
    out: list[str] = [];
    for p in [rpt ->:Contains:->][?:Package] { if query in p.pid { out.append(p.pid); } if query in p.path { out.append(p.pid); } }
    for m in [rpt ->:Contains:->][?:Module] { if query in m.mid { out.append(m.mid); } if query in m.path { out.append(m.mid); } }
    for r in [rpt ->:Contains:->][?:Relation] { if query in r.rel_id { out.append(r.rel_id); } }
    for d in [rpt ->:Contains:->][?:Diagnostic] { if query in d.did { out.append(d.did); } }
    return sorted(out);
}
def filter_diagnostics(rpt: Report, severity: str, status: str, analyzer: str) -> list[str] {
    out: list[str] = [];
    for d in [rpt ->:Contains:->][?:Diagnostic] {
        ok: bool = True;
        if severity != "" { if d.severity != severity { ok = False; } }
        if status != "" { if d.status != status { ok = False; } }
        if analyzer != "" { if d.analyzer != analyzer { ok = False; } }
        if ok { out.append(d.did); }
    }
    return sorted(out);
}
def render_report_html(rpt: Report, include_snippets: bool) -> str {
    # malformed check
    if rpt.rid == "" { return "<html><body><h1>Error: malformed report missing rid</h1></body></html>"; }
    if rpt.run_hash == "" { return "<html><body><h1>Error: malformed report missing run_hash</h1></body></html>"; }
    pkgs: list[Package] = [rpt ->:Contains:->][?:Package];
    mods: list[Module] = [rpt ->:Contains:->][?:Module];
    rels: list[Relation] = [rpt ->:Contains:->][?:Relation];
    diags: list[Diagnostic] = [rpt ->:Contains:->][?:Diagnostic];
    evs: list[Evidence] = [rpt ->:Contains:->][?:Evidence];
    # deterministic ordering
    pkg_ids: list[str] = [];
    for p in pkgs { pkg_ids.append(p.pid); }
    pkg_ids = sorted(pkg_ids);
    mod_ids: list[str] = [];
    for m in mods { mod_ids.append(m.mid); }
    mod_ids = sorted(mod_ids);
    rel_ids: list[str] = [];
    for r in rels { rel_ids.append(r.rel_id); }
    rel_ids = sorted(rel_ids);
    diag_ids: list[str] = [];
    for d in diags { diag_ids.append(d.did); }
    diag_ids = sorted(diag_ids);
    html: str = "<html><head><style>body{font-family:monospace}</style></head><body>";
    html += "<section id=\"architecture\">";
    html += "<h2>Architecture</h2>";
    for pid in pkg_ids {
        html += "<div id=\"pkg-" + pid + "\">" + pid + "</div>";
    }
    for mid in mod_ids {
        html += "<div id=\"mod-" + mid + "\">" + mid + "</div>";
    }
    for rid in rel_ids {
        html += "<a id=\"rel-" + rid + "\" href=\"#rel-" + rid + "\">" + rid + "</a>";
    }
    html += "</section>";
    html += "<section id=\"diagnostics\">";
    for d in diags {
        html += "<div id=\"diag-" + d.did + "\" data-severity=\"" + d.severity + "\" data-status=\"" + d.status + "\" data-analyzer=\"" + d.analyzer + "\">" + d.did + "</div>";
    }
    html += "</section>";
    html += "<section id=\"evidence\">";
    for e in evs {
        html += "<div id=\"ev-" + e.eid + "\">" + e.path + ":" + str(e.line_start) + "-" + str(e.line_end) + "#" + e.hash_val + "</div>";
        if include_snippets {
            html += "<pre>snippet:" + e.eid + "</pre>";
        }
    }
    html += "</section>";
    html += "<section id=\"coverage\">";
    for p in pkgs {
        if p.provenance == "unknown" { html += "<span>unknown:" + p.pid + "</span>"; }
        if p.provenance == "not-analyzed" { html += "<span>not-analyzed:" + p.pid + "</span>"; }
    }
    for m in mods {
        if m.provenance == "unknown" { html += "<span>unknown:" + m.mid + "</span>"; }
        if m.provenance == "not-analyzed" { html += "<span>not-analyzed:" + m.mid + "</span>"; }
    }
    html += "</section>";
    html += "</body></html>";
    return html;
}

walker BootstrapWalker {
    has claimed: dict[str, bool] = {};
    can boot with Report entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        print(here.rid);
        visit [] else { disengage; }
    }
}
with entry {
    demo = Report(rid="demo", run_hash="abc");
    root ++> demo;
    w = root spawn BootstrapWalker(claimed={});
    print("demo ready");
}
