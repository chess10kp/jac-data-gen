# iss_lost-rob0t__starintel-auto-research__165.jac

node Capability {
    has name: str;
    has classification: str;
    has rationale: str = "";
}

edge DependsOn {}

def semantic_names() -> list[str] {
    return [
        "bounded parallel fan-out over a dynamic provider registry",
        "bounded recursive pivots with visited-set/cycle control",
        "declarative playbook composition and result bindings",
        "conditional/failure branches in playbooks",
        "dynamic activation of capabilities from newly emitted document types",
        "persistent provider health/drift state",
        "circuit breaker / provider demotion semantics",
        "registry refresh/version pinning",
        "typed partial-result aggregation across many providers",
        "provenance-preserving deduplication and multi-source confirmation",
        "correlation-rule declarations with explanations",
        "cross-domain invocation preserving cause/provenance",
        "scan profiles/budgets such as fast/balanced/exhaustive",
        "proxy/Tor/I2P transport policy as an adapter selection concern",
        "authenticated session references and expiry without embedding raw credentials in plans",
        "scheduled/stream ingestor triggers",
        "change-set generation between repeated runs"
    ];
}

def classify_semantic(name: str) -> str {
    if name not in semantic_names() {
        return "";
    }
    if name in [
        "declarative playbook composition and result bindings",
        "correlation-rule declarations with explanations",
        "cross-domain invocation preserving cause/provenance",
        "scheduled/stream ingestor triggers"
    ] {
        return "StarLang extension needed";
    }
    if name == "proxy/Tor/I2P transport policy as an adapter selection concern" {
        return "Common Lisp adapter needed";
    }
    return "expressible now";
}

def build_catalog() -> dict[str, Capability] {
    catalog: dict[str, Capability] = {};
    for name in semantic_names() {
        cap = Capability(name=name, classification=classify_semantic(name));
        catalog[name] = cap;
    }
    catalog["bounded recursive pivots with visited-set/cycle control"]
        +>:DependsOn:+> catalog["bounded parallel fan-out over a dynamic provider registry"];
    catalog["typed partial-result aggregation across many providers"]
        +>:DependsOn:+> catalog["bounded parallel fan-out over a dynamic provider registry"];
    catalog["provenance-preserving deduplication and multi-source confirmation"]
        +>:DependsOn:+> catalog["typed partial-result aggregation across many providers"];
    catalog["correlation-rule declarations with explanations"]
        +>:DependsOn:+> catalog["provenance-preserving deduplication and multi-source confirmation"];
    catalog["change-set generation between repeated runs"]
        +>:DependsOn:+> catalog["provenance-preserving deduplication and multi-source confirmation"];
    return catalog;
}

walker DependencyWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can collect with Capability entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.name);
        print(here.name);
        for kid in [here ->:DependsOn:->][?:Capability] {
            visit :0: [kid];
        }
    }
}

def dependency_closure(catalog: dict[str, Capability], name: str) -> list[str] {
    if name not in catalog {
        return [];
    }
    graph_root = catalog[name];
    w = graph_root spawn DependencyWalker(claimed={});
    return w.found;
}

def supported_semantics() -> list[str] {
    result: list[str] = [];
    for name in semantic_names() {
        if classify_semantic(name) == "expressible now" {
            result.append(name);
        }
    }
    return sorted(result);
}

test "diamond revisit is skipped" {
    graph_root = Capability(name="root", classification="expressible now");
    left = Capability(name="left", classification="expressible now");
    right = Capability(name="right", classification="expressible now");
    shared = Capability(name="leaf", classification="expressible now");
    catalog: dict[str, Capability] = {};
    catalog["root"] = graph_root;
    catalog["left"] = left;
    catalog["right"] = right;
    catalog["leaf"] = shared;
    graph_root +>:DependsOn:+> left;
    graph_root +>:DependsOn:+> right;
    left +>:DependsOn:+> shared;
    right +>:DependsOn:+> shared;
    assert (sorted(dependency_closure(catalog, "root")) == ["leaf", "left", "right", "root"]);
}

test "cyclic pivots terminate" {
    a = Capability(name="a", classification="expressible now");
    b = Capability(name="b", classification="expressible now");
    catalog: dict[str, Capability] = {};
    catalog["a"] = a;
    catalog["b"] = b;
    a +>:DependsOn:+> b;
    b +>:DependsOn:+> a;
    assert (sorted(dependency_closure(catalog, "a")) == ["a", "b"]);
}

test "unknown semantic is tolerated" {
    assert (classify_semantic("not-in-the-research") == "");
    catalog = build_catalog();
    assert (dependency_closure(catalog, "missing") == []);
}

test "catalog classifications are deterministic" {
    catalog = build_catalog();
    assert (len(catalog) == 17);
    assert (supported_semantics() == sorted(supported_semantics()));
    assert (classify_semantic("proxy/Tor/I2P transport policy as an adapter selection concern") == "Common Lisp adapter needed");
}
