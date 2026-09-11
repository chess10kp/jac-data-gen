"""Dependency-graph collection, lifted to OSP.

Artifacts become Artifact nodes, dependency entries become typed Depends
edges, and both the crashing recursive accept walk and the iterative
work-stack walk collapse into one walker over typed edges: walkers do not
recurse, so the deep-chain stack overflow of the recursive collector cannot
occur, and the iterative remediation adds nothing to preserve. The
once-per-artifact claim map is the walk's cycle policy; output is
normalized to sorted artifact ids, matching the source contract.
Ref: apache/maven-dependency-tree#130
"""
node Artifact {
    has name: str;
}
edge Depends {}

"""Loader handle: artifact ids resolve through this lookup map."""
obj Tree {
    has arts: dict[str, Artifact];

    def resolve(name: str) -> Artifact | None {
        return self.arts.get(name);
    }
}

"""Deterministic fresh-graph builder from an {artifact: [deps]} spec."""
def load_tree(graph: dict[str, list[str]]) -> Tree {
    tree = Tree(arts={});
    names: set[str] = set(graph.keys());
    for k in graph.keys() { names = names | set(graph[k]); }
    for name in names {
        a = Artifact(name=name);
        root ++> a;
        tree.arts[name] = a;
    }
    for name in graph.keys() {
        for dep in graph[name] {
            if dep in tree.arts {
                tree.arts[name] +>:Depends:+> tree.arts[dep];
            }
        }
    }
    return tree;
}

walker CollectWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Artifact entry {
        # Cycle policy: one visit per artifact regardless of path count.
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        # Plain visit: an else-disengage would kill the whole flooded walk
        # while unvisited siblings are still queued; dead ends just queue
        # nothing and the claim map terminates the walk.
        visit [->:Depends:->];
    }
}

"""Recursive-path facade: sorted dependency closure of ``root``."""
def collect(graph: dict[str, list[str]], `root: str) -> list {
    tree = load_tree(graph);
    r = tree.resolve(`root);
    if r is None {
        return [`root];  # unknown root: closure is the lone artifact
    }
    w = r spawn CollectWalk(claimed={}, order=[]);
    return sorted(w.order);
}

"""Iterative-path facade: same closure; the walker never recurses."""
def collect_iter(graph: dict[str, list[str]], `root: str) -> list {
    tree = load_tree(graph);
    r = tree.resolve(`root);
    if r is None {
        return [`root];  # unknown root: closure is the lone artifact
    }
    w = r spawn CollectWalk(claimed={}, order=[]);
    return sorted(w.order);
}

"""Number of artifacts in the dependency closure of ``root``."""
def count_nodes(graph: dict[str, list[str]], `root: str) -> int {
    return len(collect_iter(graph, `root));
}


test "diamond closure collects each artifact once" {
    diamond = {
        "root": ["left", "right"],
        "left": ["shared", "extra"],
        "right": ["shared"],
        "extra": [],
        "shared": [],
    };
    assert collect(diamond, "root") == ["extra", "left", "right", "root", "shared"];
    assert collect_iter(diamond, "root") == ["extra", "left", "right", "root", "shared"];
    assert count_nodes(diamond, "root") == 5;
}

test "shallow tree closure via recursive-path facade" {
    tree = {"app": ["web", "db"], "web": ["util"], "db": ["util", "log"], "util": ["log"], "log": []};
    assert collect(tree, "app") == ["app", "db", "log", "util", "web"];
    assert collect_iter(tree, "app") == ["app", "db", "log", "util", "web"];
    assert count_nodes(tree, "app") == 5;
}

test "deep 5000-level chain resolves without recursion" {
    deep = {};
    for i in range(5000) { deep[f"n{i}"] = [f"n{i+1}"]; }
    deep["n5000"] = [];
    res = collect_iter(deep, "n0");
    assert len(res) == 5001;
    assert res[0] == "n0" and res[1] == "n1";
    assert res[5000] == "n999";
    assert count_nodes(deep, "n0") == 5001;
}

test "cyclic chain terminates via claim map" {
    cyc = {"a": ["b"], "b": ["c"], "c": ["b"]};
    assert collect(cyc, "a") == ["a", "b", "c"];
    assert collect_iter(cyc, "a") == ["a", "b", "c"];
    assert count_nodes(cyc, "a") == 3;
}

test "adversarial edge order revisits before deeper first-visits" {
    adv = {"root": ["shared", "mid"], "mid": ["shared", "deep"], "shared": ["deep"], "deep": []};
    assert collect(adv, "root") == ["deep", "mid", "root", "shared"];
    assert collect_iter(adv, "root") == ["deep", "mid", "root", "shared"];
    assert count_nodes(adv, "root") == 4;
}

test "unknown root closure is the lone artifact" {
    g = {"a": ["b"], "b": []};
    assert collect(g, "ghost") == ["ghost"];
    assert collect_iter(g, "ghost") == ["ghost"];
    assert count_nodes(g, "ghost") == 1;
}
