"""arnaud18o5/sysml-ai-copilot#33 — impact analysis over SysML element relationships."""

node Element {
    has eid: str;
}

edge TypedBy {}
edge ConnectsTo {}
edge Satisfies {}

def _resolve(eid: str) -> Element | None {
    for nd in [root -->][?:Element] {
        if nd.eid == eid { return nd; }
    }
    return None;
}

walker ImpactWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";
    has depth: int = 0;
    has max_depth: int = 3;

    can step with Element entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        if here.eid != self.origin { self.found.append(here.eid); }
        if self.depth >= self.max_depth { skip; }
        nbs = [here -->][?:Element];
        nms: list[str] = [];
        for n in nbs { nms.append(n.eid); }
        for nm in sorted(nms) {
            for n in nbs {
                if n.eid == nm {
                    n spawn ImpactWalk(
                        claimed=self.claimed,
                        found=self.found,
                        origin=self.origin,
                        depth=self.depth + 1,
                        max_depth=self.max_depth,
                    );
                }
            }
        }
    }
}

walker ImpactPathWalk {
    has trail: list[str] = [];
    has paths: list[list[str]] = [];
    has target: str = "";
    has max_depth: int = 3;

    can step with Element entry {
        if here.eid in self.trail { skip; }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.eid);
        if here.eid == self.target {
            row: list[str] = [];
            for x in nt { row.append(x); }
            self.paths.append(row);
            skip;
        }
        if len(nt) >= self.max_depth { skip; }
        nbs = [here -->][?:Element];
        nms: list[str] = [];
        for n in nbs { nms.append(n.eid); }
        for nm in sorted(nms) {
            for n in nbs {
                if n.eid == nm {
                    n spawn ImpactPathWalk(
                        trail=nt,
                        paths=self.paths,
                        target=self.target,
                        max_depth=self.max_depth,
                    );
                }
            }
        }
    }
}

def load_element_graph(
    elements: list[str],
    typed_by: list[tuple[str, str]],
    connects_to: list[tuple[str, str]],
    satisfies: list[tuple[str, str]],
) -> dict[str, object] {
    nodes: dict[str, Element] = {};
    for eid in elements {
        nd = Element(eid=eid);
        root ++> nd;
        nodes[eid] = nd;
    }
    for (usage, typ) in typed_by {
        u = nodes.get(usage, None);
        t = nodes.get(typ, None);
        if u is not None and t is not None {
            u +>:TypedBy:+> t;
            t +>:TypedBy:+> u;
        }
    }
    for (left, right) in connects_to {
        a = nodes.get(left, None);
        b = nodes.get(right, None);
        if a is not None and b is not None {
            a +>:ConnectsTo:+> b;
            b +>:ConnectsTo:+> a;
        }
    }
    for (left, right) in satisfies {
        a = nodes.get(left, None);
        b = nodes.get(right, None);
        if a is not None and b is not None {
            a +>:Satisfies:+> b;
            b +>:Satisfies:+> a;
        }
    }
    adj: dict[str, list[str]] = {};
    for eid in elements {
        adj[eid] = [];
        for nb in [nodes[eid] -->][?:Element] {
            dup = False;
            for x in adj[eid] { if x == nb.eid { dup = True; } }
            if not dup { adj[eid].append(nb.eid); }
        }
    }
    el_out: list[str] = [];
    for e in elements { el_out.append(e); }
    return {"elements": el_out, "adj": adj};
}

def impact_analysis(
    g: dict[str, object],
    element_id: str,
    *,
    max_depth: int = 3,
) -> list[str] {
    adj = g["adj"] as dict[str, list[str]];
    if element_id not in adj { return []; }
    start = _resolve(element_id);
    if start is None { return []; }
    w = start spawn ImpactWalk(
        claimed={}, found=[], origin=element_id, depth=0, max_depth=max_depth
    );
    return sorted(w.found);
}

def impact_paths(
    g: dict[str, object],
    element_id: str,
    target: str,
    *,
    max_depth: int = 3,
) -> list[list[str]] {
    adj = g["adj"] as dict[str, list[str]];
    if element_id not in adj or target not in adj { return []; }
    start = _resolve(element_id);
    if start is None { return []; }
    w = start spawn ImpactPathWalk(
        trail=[], paths=[], target=target, max_depth=max_depth
    );
    out: list[list[str]] = [];
    for p in w.paths {
        row: list[str] = [];
        for x in p { row.append(x); }
        out.append(row);
    }
    return sorted(out);
}
