"""Dependency-tree renderer with shared-node visibility, lifted to OSP.

The recursive per-path walk becomes a fan of BranchRender walkers: every
branch spawns its own walker carrying a COPY of the root-to-node path, so
a module reachable from two branches renders under both (the issue's fix)
while repeats along one path are denied. Closure queries become flooding
walkers over typed Needs / UsedBy edges with claim-map cycle policy --
jac 0.36.1 walkers do not dedupe, so revisits are `skip`ed explicitly.
Ref: ut-issl/veriq#260
"""
node Module {
    has name: str;
}
edge Needs {}    # user -> dependency
edge UsedBy {}   # dependency -> user

obj RenderSink {
    has rendered: list[str];
}

"""Loader handle: id-string parameters resolve through this lookup map."""
obj Tree {
    has modules: dict[str, Module];
    has names: list[str];

    def resolve(name: str) -> Module | None {
        return self.modules.get(name);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def load_tree(names: list[str], depends_on: list[tuple[str, str]]) -> Tree {
    tree = Tree(modules={}, names=[]);
    for n in names {
        m = Module(name=n);
        root ++> m;
        tree.modules[n] = m;
        tree.names.append(n);
    }
    for (user, used) in depends_on {
        u = tree.modules[user];
        d = tree.modules[used];
        u +>:Needs:+> d;
        d +>:UsedBy:+> u;
    }
    return tree;
}

walker BranchRender {
    has path: dict[str, bool] = {};
    has parent_name: str = "";
    has sink: RenderSink | None = None;

    can step with Module entry {
        # Per-path policy: deny only if already on THIS root-to-node path.
        if here.name in self.path {
            skip;
        }
        path = dict(self.path);
        path[here.name] = True;
        if self.parent_name != "" and self.sink is not None {
            self.sink.rendered.append(self.parent_name + ">" + here.name);
        }
        # Each branch gets a fresh walker with a copied path.
        for k in [here->:Needs:->] {
            k spawn BranchRender(path=path, parent_name=here.name, sink=self.sink);
        }
    }
}

# (`root` is a jac keyword, hence root_name)
def render_edges(tree: Tree, root_name: str) -> list[str] {
    start = tree.resolve(root_name);
    if start is None {
        return [];
    }
    sink = RenderSink(rendered=[]);
    start spawn BranchRender(path={}, parent_name="", sink=sink);
    return sorted(sink.rendered);
}

walker DepFlood {
    has claimed: dict[str, bool] = {};
    has members: list[str] = [];

    can step with Module entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.members.append(here.name);
        visit [->:Needs:->];
    }
}

walker UsedByFlood {
    has claimed: dict[str, bool] = {};
    has members: list[str] = [];

    can step with Module entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.members.append(here.name);
        visit [->:UsedBy:->];
    }
}

# (`node` is a jac keyword, hence name)
def dependencies_of(tree: Tree, name: str) -> list[str] {
    start = tree.resolve(name);
    if start is None {
        return [name];
    }
    w = start spawn DepFlood(claimed={});
    return sorted(w.members);
}

# (`node` is a jac keyword, hence name)
def dependents_of(tree: Tree, name: str) -> list[str] {
    start = tree.resolve(name);
    if start is None {
        return [name];
    }
    w = start spawn UsedByFlood(claimed={});
    return sorted(w.members);
}
