"""cue-lang/cue#2555 — CUE package evaluator with file-order-sensitive reference closure."""

node CueFile {
    has fname: str;
    has deployment_comp: bool = False;
    has oauth_comp: bool = False;
    has template: bool = False;
    has instances: dict[str, str] = {};
}

edge Refs: CueFile --> CueFile {}

walker TransitiveRefsWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with CueFile entry {
        if here.fname in self.claimed { skip; }
        self.claimed[here.fname] = True;
        if here.fname != self.origin { self.found.append(here.fname); }
        visit [->:Refs:->][?:CueFile];
    }
}

walker CycleDFSWalk {
    has visited: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has cycles: list[str] = [];
    has valid_files: dict[str, bool] = {};

    can step with CueFile entry {
        if here.fname in self.visited {
            if here.fname in self.stack { self.cycles.append(here.fname); }
            skip;
        }
        self.visited[here.fname] = True;
        self.stack[here.fname] = True;
        kids = [here ->:Refs:->][?:CueFile];
        nms: list[str] = [];
        for n in kids {
            if n.fname in self.valid_files { nms.append(n.fname); }
        }
        for nm in sorted(nms) {
            for n in kids {
                if n.fname == nm {
                    n spawn CycleDFSWalk(
                        visited=self.visited,
                        stack=self.stack,
                        cycles=self.cycles,
                        valid_files=self.valid_files,
                    );
                }
            }
        }
        del self.stack[here.fname];
    }
}

obj PackageGraph {
    has files: dict[str, dict[str, object]] = {};
    has refs: dict[str, list[str]] = {};
    has file_nodes: dict[str, CueFile] = {};
}

def load_package(
    files: list[tuple[str, dict[str, object]]],
    refs: list[tuple[str, str]] | None = None,
) -> PackageGraph {
    pkg = PackageGraph();
    for (fname, spec) in files {
        pkg.files[fname] = dict(spec);
        pkg.refs.setdefault(fname, []);
        s = dict(spec);
        inst_raw = s.get("instances", {});
        inst: dict[str, str] = {};
        if inst_raw is not None {
            for (k, v) in dict(inst_raw).items() { inst[str(k)] = str(v); }
        }
        nd = CueFile(
            fname=fname,
            deployment_comp=bool(s.get("deployment_comp", False)),
            oauth_comp=bool(s.get("oauth_comp", False)),
            template=bool(s.get("template", False)),
            instances=inst,
        );
        root ++> nd;
        pkg.file_nodes[fname] = nd;
    }
    ref_list = refs if refs is not None else [];
    for (src, dst) in ref_list {
        if src in pkg.files {
            pkg.refs.setdefault(src, []).append(dst);
            sn = pkg.file_nodes.get(src, None);
            dn = pkg.file_nodes.get(dst, None);
            if sn is not None and dn is not None { sn +>:Refs:+> dn; }
        }
    }
    return pkg;
}

def resolve_load_order(pkg: PackageGraph, order: list[str] | None = None) -> list[str] {
    if order is not None {
        out: list[str] = [];
        for f in order {
            if f in pkg.files { out.append(f); }
        }
        return out;
    }
    return sorted(pkg.files.keys());
}

def transitive_field_refs(pkg: PackageGraph, file_id: str) -> list[str] {
    if file_id not in pkg.files { return []; }
    nd = pkg.file_nodes.get(file_id, None);
    if nd is None { return []; }
    w = nd spawn TransitiveRefsWalk(claimed={}, found=[], origin=file_id);
    return sorted(w.found);
}

def cyclic_reference_fields(pkg: PackageGraph) -> list[str] {
    visited: dict[str, bool] = {};
    cycles: list[str] = [];
    valid: dict[str, bool] = {};
    for fn in pkg.files { valid[fn] = True; }
    for fn in sorted(pkg.files.keys()) {
        if fn not in visited {
            nd = pkg.file_nodes.get(fn, None);
            if nd is not None {
                nd spawn CycleDFSWalk(
                    visited=visited,
                    stack={},
                    cycles=cycles,
                    valid_files=valid,
                );
            }
        }
    }
    uniq: dict[str, bool] = {};
    for c in cycles { uniq[c] = True; }
    out: list[str] = [];
    for c in uniq.keys() { out.append(c); }
    return sorted(out);
}

def export_package(
    pkg: PackageGraph,
    load_order: list[str] | None = None,
) -> dict[str, object] | str {
    order = resolve_load_order(pkg, load_order);
    deployment: dict[str, str] = {};
    oauth: dict[str, str] = {};
    deployment_comprehension_ran = False;
    deployment_at_comprehension: dict[str, bool] = {};
    for fname in order {
        spec = pkg.files[fname];
        if spec.get("deployment_comp", False) {
            deployment_comprehension_ran = True;
            deployment_at_comprehension = {};
            for k in deployment.keys() { deployment_at_comprehension[k] = True; }
        }
        inst_raw = spec.get("instances", {});
        inst_dict: dict[str, object] = dict(inst_raw) if inst_raw is not None else {};
        for (iid, iname) in sorted(inst_dict.items()) {
            oauth[str(iid)] = str(iname);
        }
        if spec.get("oauth_comp", False) {
            oauth_items: list[tuple[str, str]] = [];
            for (iid, iname) in oauth.items() { oauth_items.append((iid, iname)); }
            for (iid, iname) in sorted(oauth_items) {
                dep_key = f"{iname}-proxy";
                if deployment_comprehension_ran and dep_key not in deployment_at_comprehension {
                    return (
                        f'deployment: field "{dep_key}" not allowed by earlier '
                        + "comprehension or reference cycle"
                    );
                }
                deployment[dep_key] = "proxy";
            }
        }
    }
    dep_out: dict[str, str] = {};
    for (k, v) in sorted(deployment.items()) { dep_out[k] = v; }
    oauth_out: dict[str, str] = {};
    for (k, v) in sorted(oauth.items()) { oauth_out[k] = v; }
    return {"deployment": dep_out, "oAuthProxy": oauth_out};
}

def kube_reproducer(rename_z_to_a: bool = False) -> PackageGraph {
    zfile = "a.cue" if rename_z_to_a else "z.cue";
    return load_package(
        [
            (zfile, {"deployment_comp": True}),
            ("b.cue", {"oauth_comp": True, "template": True}),
            ("c.cue", {"instances": {"prometheus": "prometheus"}}),
        ],
        [
            ("b.cue", "c.cue"),
            ("b.cue", zfile),
            (zfile, "b.cue"),
        ],
    );
}
