"""Reify construct-level dependencies into resource-level depends_on, lifted to OSP.

Constructs become Construct nodes; the children map becomes typed
Composition edges (parent -> child); construct-level addDependency
declarations become typed Depends edges. The manual stack sweep over the
children map becomes a walker descending Composition edges whose dead ends
ARE the leaf resources; crossing a Depends edge into the target subtree is
a fresh spawn of the same leaf walker at the target construct, so every
declaration cross-products its two leaf sets. Self pairs are skipped so a
dependency on an ancestor never makes a resource depend on itself. The
claim map is the cycle policy for diamond-shaped child lists; unknown
construct paths raise KeyError exactly like the source.
Ref: open-constructs/cdk-terrain#354
"""
node Construct {
    has path: str;
}
edge Composition {}
edge Depends {}

"""Loader handle: construct paths resolve through this lookup map."""
obj Model {
    has constructs: dict[str, Construct];

    def resolve(path: str) -> Construct | None {
        return self.constructs.get(path);
    }
}

"""Deterministic fresh-graph builder from a {path: [child paths]} tree spec."""
def load_model(tree: dict[str, list[str]], deps: list[tuple[str, str]]) -> Model {
    m = Model(constructs={});
    for path in tree.keys() {
        c = Construct(path=path);
        root ++> c;
        m.constructs[path] = c;
    }
    for path in tree.keys() {
        for kid in tree[path] {
            child = m.resolve(kid);
            if child is not None {
                m.constructs[path] +>:Composition:+> child;
            }
        }
    }
    for pair in deps {
        src = m.resolve(pair[0]);
        dst = m.resolve(pair[1]);
        if src is None {
            raise KeyError(pair[0]);
        }
        if dst is None {
            raise KeyError(pair[1]);
        }
        src +>:Depends:+> dst;
    }
    return m;
}

"""Leaf collector: descends Composition edges; a dead end IS a leaf resource."""
walker LeavesWalk {
    has claimed: dict[str, bool] = {};
    has leaves: list[str] = [];

    can step with Construct entry {
        # Cycle policy: one visit per construct regardless of path count.
        if here.path in self.claimed {
            skip;
        }
        self.claimed[here.path] = True;
        # a dead end IS a leaf resource; keep walking remaining branches
        visit [->:Composition:->] else { self.leaves.append(here.path); }
    }
}

"""Every leaf resource path beneath construct ``path``, sorted."""
def leaves_under(tree: dict[str, list[str]], path: str) -> list {
    m = load_model(tree, []);
    c = m.resolve(path);
    if c is None {
        raise KeyError(path);
    }
    w = c spawn LeavesWalk(claimed={}, leaves=[]);
    return sorted(w.leaves);
}

"""Reify construct-level dependencies into leaf-to-leaf depends_on."""
def synth_dependencies(tree: dict[str, list[str]], deps: list[tuple[str, str]]) -> dict {
    m = load_model(tree, deps);
    out: dict = {};
    # one subtree walk per declaration; crossing its Depends edges spawns
    # the leaf walker inside each target subtree (the N x M cross product)
    for pair in deps {
        src = m.resolve(pair[0]);
        if src is None {
            raise KeyError(pair[0]);
        }
        sw = src spawn LeavesWalk(claimed={}, leaves=[]);
        targets: list[Construct] = [src ->:Depends:->];
        for tgt in targets {
            tw = tgt spawn LeavesWalk(claimed={}, leaves=[]);
            for s_leaf in sw.leaves {
                for d_leaf in tw.leaves {
                    if s_leaf != d_leaf {
                        if s_leaf not in out {
                            out[s_leaf] = [];
                        }
                        if d_leaf not in out[s_leaf] {
                            out[s_leaf].append(d_leaf);
                        }
                    }
                }
            }
        }
    }
    for k in out.keys() {
        out[k] = sorted(out[k]);
    }
    return out;
}
