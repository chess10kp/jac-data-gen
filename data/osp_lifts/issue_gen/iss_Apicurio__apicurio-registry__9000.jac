"""Apicurio/apicurio-registry#9000 — Reference tree resolve keyed by GAV."""

obj RefRegistry {
    has artifacts: dict[str, Artifact] = {};
}
node Artifact {
    has gav: str;
    has body: str;
}
edge RefersTo { has ref_name: str = ""; }

walker ResolveWalk {
    has claimed: dict[str, bool] = {};
    has hits: dict[str, str] = {};
    can step with Artifact entry {
        if here.gav in self.claimed { skip; }
        self.claimed[here.gav] = True;
        self.hits[here.gav] = here.body;
        visit [->:RefersTo:->][?:Artifact];
    }
}

def gav_key(group: str, artifact: str, version: str) -> str {
    return group + ":" + artifact + ":" + version;
}

def load_registry(
    artifacts: list[tuple[str, str, str, str]],
    ref_edges: list[tuple[str, str, str, str, str, str, str]],
) -> RefRegistry {
    reg = RefRegistry();
    for (group, artifact, version, body) in artifacts {
        key = gav_key(group, artifact, version);
        if key not in reg.artifacts {
            nd = Artifact(gav=key, body=body);
            root ++> nd;
            reg.artifacts[key] = nd;
        }
    }
    for (
        owner_g, owner_a, owner_v,
        ref_name, ref_g, ref_a, ref_v,
    ) in ref_edges {
        owner = reg.artifacts.get(gav_key(owner_g, owner_a, owner_v), None);
        target = reg.artifacts.get(gav_key(ref_g, ref_a, ref_v), None);
        if owner is None or target is None { continue; }
        owner +>:RefersTo(ref_name=ref_name):+> target;
    }
    return reg;
}

def resolve_tree(reg: RefRegistry, root_gav: str) -> dict[str, str] {
    start = reg.artifacts.get(root_gav, None);
    if start is None { return {}; }
    w = start spawn ResolveWalk(claimed={}, hits={});
    return w.hits;
}
