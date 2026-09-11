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
