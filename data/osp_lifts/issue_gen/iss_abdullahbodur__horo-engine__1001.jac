"""Prefab expansion with deterministic per-instance ID namespacing, lifted to OSP.

Prefabs and their local nodes become Prefab / PNode archetypes connected
by typed Contains edges (the local hierarchy) and a typed Root edge from
each prefab to its root node; scene instances become Instance nodes whose
typed Instantiates edges resolve them against the shared immutable prefab
snapshot. The recursive instantiation becomes a walker cascading down
Contains edges from the prefab root, remapping every local id into the
instance namespace ``inst:<iid>:<local>``; expanded parent links are
recovered from reverse Contains queries, so the edge set falls out of the
walk. Each instance spawns its own walker with its own namespace and
claim map, so a shared prefab expands per instance into disjoint ID
spaces. An instance whose Instantiates edge resolves to nothing raises
KeyError before any output: resolution fails closed.
Ref: abdullahbodur/horo-engine#1001
"""
node Prefab {
    has name: str;
}
node PNode {
    has local: str;
}
node Instance {
    has iid: str;
    has wants: str;
}
edge Contains {}
edge Root {}
edge Instantiates {}

"""Loader handle: the immutable prefab snapshot plus the scene instances."""
obj Snap {
    has prefabs: dict[str, Prefab];
    has pnodes: dict[str, PNode];
    has instances: list[Instance];
}

"""Deterministic fresh-graph builder from the {name: {root, nodes}} snapshot."""
def load_snap(scene: list, prefabs: dict) -> Snap {
    s = Snap(prefabs={}, pnodes={}, instances=[]);
    for name in prefabs.keys() {
        p = Prefab(name=name);
        root ++> p;
        s.prefabs[name] = p;
    }
    for name in prefabs.keys() {
        spec: dict = prefabs[name];
        table: dict = spec.get("nodes", {});
        rl: str = spec["root"];
        # every local id: table keys, referenced children, and the root
        allkids: list[str] = [];
        for local in table.keys() {
            entry: dict = table[local];
            kids: list = entry.get("children", []);
            for kid in kids {
                allkids.append(kid);
            }
        }
        locals_: set[str] = set(table.keys()) | set(allkids) | set([rl]);
        for local in locals_ {
            n = PNode(local=local);
            root ++> n;
            s.pnodes[name + "/" + local] = n;
        }
        for local in table.keys() {
            entry: dict = table[local];
            kids: list = entry.get("children", []);
            for kid in kids {
                s.pnodes[name + "/" + local] +>:Contains:+> s.pnodes[name + "/" + kid];
            }
        }
        s.prefabs[name] +>:Root:+> s.pnodes[name + "/" + rl];
    }
    for inst in scene {
        i = Instance(iid=inst["id"], wants=inst["prefab"]);
        root ++> i;
        s.instances.append(i);
        p = s.prefabs.get(inst["prefab"]);
        if p is not None {
            i +>:Instantiates:+> p;
        }
    }
    return s;
}

"""Namespacing cascade: expand one prefab subtree into an instance namespace."""
walker ExpandWalk {
    has prefix: str = "";
    has claimed: dict[str, bool] = {};
    has nodes: list[str] = [];
    has edges: list = [];

    can step with PNode entry {
        # Cycle policy: expand each local id once per instance.
        if here.local in self.claimed {
            skip;
        }
        self.claimed[here.local] = True;
        me = self.prefix + here.local;
        self.nodes.append(me);
        pars: list[PNode] = [here <-:Contains:<-];
        for par in pars {
            self.edges.append([self.prefix + par.local, me]);
        }
        visit [->:Contains:->];
    }
}

"""Expand prefab instances into concrete scene nodes and hierarchy edges."""
def expand(scene: list, prefabs: dict) -> dict {
    s = load_snap(scene, prefabs);
    nodes: list[str] = [];
    edges: list = [];
    for i in s.instances {
        ps: list[Prefab] = [i ->:Instantiates:->];
        if len(ps) == 0 {
            raise KeyError(i.wants);  # fail closed: no partial result
        }
        roots: list[PNode] = [ps[0] ->:Root:->];
        if len(roots) == 0 {
            continue;
        }
        w = roots[0] spawn ExpandWalk(
            prefix="inst:" + i.iid + ":", claimed={}, nodes=[], edges=[]
        );
        for n in w.nodes {
            if n not in nodes {
                nodes.append(n);
            }
        }
        for e in w.edges {
            if e not in edges {
                edges.append(e);
            }
        }
    }
    return {"nodes": sorted(nodes), "edges": sorted(edges)};
}
