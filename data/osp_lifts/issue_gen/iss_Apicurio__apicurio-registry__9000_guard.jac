"""Guard: Apicurio/apicurio-registry#9000."""

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

test "same name different GAV preserved" {
    reg = load_registry(
        [
            ("g", "Common", "1", "body-v1"),
            ("g", "Common", "2", "body-v2"),
            ("g", "A", "1", "body-a"),
            ("g", "B", "1", "body-b"),
            ("g", "Main", "1", "body-main"),
        ],
        [
            ("g", "A", "1", "common.avsc", "g", "Common", "1"),
            ("g", "B", "1", "common.avsc", "g", "Common", "2"),
            ("g", "Main", "1", "refA", "g", "A", "1"),
            ("g", "Main", "1", "refB", "g", "B", "1"),
        ],
    );
    k1 = gav_key("g", "Common", "1");
    k2 = gav_key("g", "Common", "2");
    got = resolve_tree(reg, gav_key("g", "Main", "1"));
    assert got[k1] == "body-v1";
    assert got[k2] == "body-v2";
}

test "diamond reference tree adversarial" {
    reg = load_registry(
        [
            ("g", "hub", "1", "h"),
            ("g", "left", "1", "l"),
            ("g", "right", "1", "r"),
            ("g", "leaf", "1", "f"),
        ],
        [
            ("g", "hub", "1", "L", "g", "left", "1"),
            ("g", "hub", "1", "R", "g", "right", "1"),
            ("g", "left", "1", "F", "g", "leaf", "1"),
            ("g", "right", "1", "F", "g", "leaf", "1"),
        ],
    );
    got = resolve_tree(reg, gav_key("g", "hub", "1"));
    assert got[gav_key("g", "leaf", "1")] == "f";
}

test "cycle terminates once per gav" {
    reg = load_registry(
        [("g", "X", "1", "x"), ("g", "Y", "1", "y")],
        [
            ("g", "X", "1", "r", "g", "Y", "1"),
            ("g", "Y", "1", "r", "g", "X", "1"),
        ],
    );
    got = resolve_tree(reg, gav_key("g", "X", "1"));
    assert len(got) == 2;
}
