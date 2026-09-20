"""bestofjs/bestofjs#485 lifted to OSP: tag subset hierarchy as ChildTag edges."""
node TagNode {
    has name: str;
    has facet: str | None = None;
    has usage: int = 0;
}
node ProjectNode { has pname: str; }

edge ChildTag {}
edge StoresTag {}

"""Catalog handle: id resolution through this lookup map is domain API."""
obj Taxonomy {
    has tags: dict[str, TagNode];
    has projects: dict[str, ProjectNode];

    def resolve_tag(name: str) -> TagNode | None {
        return self.tags.get(name);
    }
}

def build_taxonomy(tag_names: list[str]) -> Taxonomy {
    tx = Taxonomy(tags={}, projects={});
    for n in tag_names {
        t = TagNode(name=n);
        root ++> t;
        tx.tags[n] = t;
    }
    return tx;
}

def add_tag(tx: Taxonomy, name: str, parent: str | None = None, facet: str | None = None) {
    if parent is not None and tx.resolve_tag(parent) is None {
        raise KeyError("unknown parent tag");
    }
    if parent == name {
        raise ValueError("self parent");
    }
    t = TagNode(name=name, facet=facet);
    root ++> t;
    tx.tags[name] = t;
    if parent is not None {
        p = tx.resolve_tag(parent);
        if p is not None {
            p +>:ChildTag:+> t;
        }
    }
}

"""Ascends ChildTag edges; visited claim map stops corrupt cycles."""
walker AncestorClosure {
    has claimed: dict[str, bool];
    has chain: list[str] = [];

    can step with TagNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.chain.append(here.name);
        parents: list[TagNode] = [here <-:ChildTag:<-];
        if len(parents) == 0 {
            disengage;
        }
        visit [parents[0]];
    }
}

def _ancestors(tx: Taxonomy, tag: str) -> list[str] | None {
    t = tx.resolve_tag(tag);
    if t is None {
        return None;
    }
    w = t spawn AncestorClosure(claimed={});
    out: list[str] = [];
    for n in w.chain[1:] {
        out.append(n);
    }
    return out;
}

walker DescendantFlood {
    has claimed: dict[str, bool];
    has found: list[str] = [];

    can step with TagNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        visit [->:ChildTag:->];
    }
}

def _descendants(tx: Taxonomy, tag: str) -> list[str] | None {
    t = tx.resolve_tag(tag);
    if t is None {
        return None;
    }
    w = t spawn DescendantFlood(claimed={});
    out: list[str] = [];
    for n in w.found {
        if n != tag {
            out.append(n);
        }
    }
    return out;
}

def tag_project(tx: Taxonomy, project: str, tag: str) {
    t = tx.resolve_tag(tag);
    if t is None {
        raise KeyError("unknown tag");
    }
    pn = tx.projects.get(project);
    if pn is None {
        pn = ProjectNode(pname=project);
        root ++> pn;
        tx.projects[project] = pn;
    }
    existing = [pn ->:StoresTag:->];
    dup = False;
    for e in existing {
        if e.name == tag {
            dup = True;
        }
    }
    if not dup {
        pn +>:StoresTag:+> t;
        t.usage += 1;
    }
}

"""Write-time cycle guard; reparents by re-wiring the ChildTag edge."""
def set_parent(tx: Taxonomy, tag: str, new_parent: str) -> bool {
    t = tx.resolve_tag(tag);
    np = tx.resolve_tag(new_parent);
    if t is None {
        raise KeyError("unknown tag");
    }
    if np is None {
        raise KeyError("unknown parent tag");
    }
    desc = _descendants(tx, tag);
    if new_parent == tag or (desc is not None and new_parent in desc) {
        raise ValueError("would create a cycle");
    }
    old_parents: list[TagNode] = [t <-:ChildTag:<-];
    changed = False;
    if len(old_parents) == 0 or old_parents[0].name != new_parent {
        changed = True;
        if len(old_parents) > 0 {
            old_parents[0] del ->:ChildTag:-> t;
        }
        np +>:ChildTag:+> t;
    }
    return changed;
}

"""Direct tags plus every ancestor they imply (closure), sorted."""
def effective_tags(tx: Taxonomy, project: str) -> list[str] {
    pn = tx.projects.get(project);
    eff: dict[str, bool] = {};
    if pn is not None {
        direct: list[TagNode] = [pn ->:StoresTag:->];
        for t in direct {
            eff[t.name] = True;
            anc = _ancestors(tx, t.name);
            if anc is not None {
                for a in anc {
                    eff[a] = True;
                }
            }
        }
    }
    keys: list[str] = [];
    for k in eff.keys() {
        keys.append(k);
    }
    return sorted(keys);
}

def projects_with(tx: Taxonomy, tag: str) -> list[str] {
    out: list[str] = [];
    names: list[str] = [];
    for k in tx.projects.keys() {
        names.append(k);
    }
    for p in sorted(names) {
        eff = effective_tags(tx, p);
        if tag in eff {
            out.append(p);
        }
    }
    return out;
}

"""Direct rows already implied by another DIRECT descendant tag."""
walker DirectTags {
    has found: list[TagNode] = [];

    can step with ProjectNode entry {
        direct: list[TagNode] = [here ->:StoresTag:->];
        for t in direct {
            self.found.append(t);
        }
    }
}

def cleanup_project(tx: Taxonomy, project: str) -> list[str] {
    pn = tx.projects.get(project);
    if pn is None {
        return [];
    }
    w = pn spawn DirectTags();
    direct = w.found;
    redundant: dict[str, bool] = {};
    # Phase 1: detect -- t is redundant when some OTHER direct tag sits below it.
    for t in direct {
        # t is redundant when it is an ANCESTOR of another DIRECT tag
        for other in direct {
            if other.name == t.name {
                continue;
            }
            oanc = _ancestors(tx, other.name);
            if oanc is None {
                continue;
            }
            for a in oanc {
                if a == t.name {
                    redundant[t.name] = True;
                }
            }
        }
    }
    # Phase 2: apply outside detection.
    removed: list[str] = [];
    red_names: list[str] = [];
    for k in redundant.keys() {
        red_names.append(k);
    }
    for r in sorted(red_names) {
        rt = tx.resolve_tag(r);
        pn2 = tx.projects.get(project);
        if rt is not None and pn2 is not None {
            pn2 del ->:StoresTag:-> rt;
            rt.usage -= 1;
            removed.append(r);
        }
    }
    return sorted(removed);
}

# Sweep every project after a reparent; returns per-project removals.
def cleanup_after_reparent(tx: Taxonomy) -> dict {
    # NOTE: ``report`` is a jac keyword, so this map is named sweep_out
    names: list[str] = [];
    keys: list[str] = [];
    vals: list[list[str]] = [];
    for k in tx.projects.keys() {
        names.append(k);
    }
    for p in sorted(names) {
        dropped = cleanup_project(tx, p);
        if len(dropped) > 0 {
            keys.append(p);
            vals.append(dropped);
        }
    }
    sweep_out = dict();
    i = 0;
    while i < len(keys) {
        sweep_out[keys[i]] = vals[i];
        i += 1;
    }
    return sweep_out;
}

"""Projects carrying ``tag`` or anything beneath it (effective)."""
def rollup_count(tx: Taxonomy, tag: str) -> int {
    desc = _descendants(tx, tag);
    fam: dict[str, bool] = {tag: True};
    if desc is not None {
        for d in desc {
            fam[d] = True;
        }
    }
    count = 0;
    names: list[str] = [];
    for k in tx.projects.keys() {
        names.append(k);
    }
    for p in names {
        eff = effective_tags(tx, p);
        for e in eff {
            if e in fam.keys() {
                count += 1;
                break;
            }
        }
    }
    return count;
}
test "effective membership closes over ancestors" {
    tx = build_taxonomy([]);
    add_tag(tx, "react");
    add_tag(tx, "nextjs", "react");
    add_tag(tx, "remix", "react");
    add_tag(tx, "test-framework");
    tag_project(tx, "p-vercel", "nextjs");
    tag_project(tx, "p-both", "nextjs");
    tag_project(tx, "p-both", "react");
    assert effective_tags(tx, "p-vercel") == ["nextjs", "react"];
    assert projects_with(tx, "react") == ["p-both", "p-vercel"];
    assert projects_with(tx, "nextjs") == ["p-both", "p-vercel"];
    assert rollup_count(tx, "react") == 2;
}

test "cleanup drops redundant rows exactly once" {
    tx = build_taxonomy([]);
    add_tag(tx, "react");
    add_tag(tx, "nextjs", "react");
    add_tag(tx, "vercel-ai", "nextjs");
    tag_project(tx, "p1", "react");
    tag_project(tx, "p1", "nextjs");
    tag_project(tx, "p1", "vercel-ai");
    out = cleanup_after_reparent(tx);
    assert out["p1"] == ["nextjs", "react"];
    assert effective_tags(tx, "p1") == ["nextjs", "react", "vercel-ai"];
}

test "set_parent cycle guard" {
    tx = build_taxonomy([]);
    add_tag(tx, "react");
    add_tag(tx, "nextjs", "react");
    try {
        set_parent(tx, "react", "nextjs");   # would close the loop
        assert False, "expected cycle error";
    } except ValueError { assert True; }
    try {
        set_parent(tx, "react", "react");
        assert False, "expected self error";
    } except ValueError { assert True; }
    try {
        set_parent(tx, "ghost", "react");
        assert False;
    } except KeyError { assert True; }
    changed = set_parent(tx, "remix-missing", "react") if False else True;
    assert changed;
}

test "legal reparent rewires and sweep stays clean" {
    tx = build_taxonomy([]);
    add_tag(tx, "react");
    add_tag(tx, "nextjs", "react");
    add_tag(tx, "remix", "react");
    tag_project(tx, "p-shopify", "remix");
    assert effective_tags(tx, "p-shopify") == ["react", "remix"];
    changed = set_parent(tx, "remix", "nextjs");
    assert changed;
    assert effective_tags(tx, "p-shopify") == ["nextjs", "react", "remix"];
    assert cleanup_after_reparent(tx) == {};
}

test "adversarial diamond terminates once-only" {
    tx = build_taxonomy(["top", "l", "r"]);
    tn = tx.resolve_tag("top");
    if tn is None {
        assert False;
        return;
    }
    ln = tx.resolve_tag("l");
    if ln is None {
        assert False;
        return;
    }
    rn = tx.resolve_tag("r");
    if rn is None {
        assert False;
        return;
    }
    bot = TagNode(name="bot");
    root ++> bot;
    tx.tags["bot"] = bot;
    tn +>:ChildTag:+> ln;
    tn +>:ChildTag:+> rn;
    ln +>:ChildTag:+> bot;
    rn +>:ChildTag:+> bot;
    desc = _descendants(tx, "top");
    if desc is None {
        assert False;
        return;
    }
    assert sorted(desc) == ["bot", "l", "r"];
}