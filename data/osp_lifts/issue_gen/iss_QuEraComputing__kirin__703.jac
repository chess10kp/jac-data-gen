# PROGRAM: iss_QuEraComputing__kirin__703.jac
# QuEraComputing/kirin#703

node Method {
    has name: str;
}

edge Calls {}

walker NeighborScan {
    has target: str;
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Method entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.name == self.target {
            for kid in [here ->:Calls:->][?:Method] {
                self.found.append(kid.name);
            }
        }
        for kid in [here ->:Calls:->][?:Method] {
            visit :0: [kid];
        }
        print(here.name);
    }
}

walker Inspect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has edges: list[str] = [];
    has backedges: list[str] = [];

    can step with Method entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.name);
        for kid in [here ->:Calls:->][?:Method] {
            self.edges.append(here.name + "->" + kid.name);
            self.backedges.append(kid.name + "->" + here.name);
            visit :0: [kid];
        }
        print(here.name);
    }
}

obj CallGraph {
    has entry: Method;

    can get_neighbors(name: str) -> list[str] {
        w = self.entry spawn NeighborScan(
            target=name, claimed={}, found=[]
        );
        return sorted(w.found);
    }

    can get_nodes -> list[str] {
        w = self.entry spawn Inspect(
            claimed={}, found=[], edges=[], backedges=[]
        );
        return sorted(w.found);
    }

    can get_edges -> list[str] {
        w = self.entry spawn Inspect(
            claimed={}, found=[], edges=[], backedges=[]
        );
        return sorted(w.edges);
    }

    can get_backedges -> list[str] {
        w = self.entry spawn Inspect(
            claimed={}, found=[], edges=[], backedges=[]
        );
        return sorted(w.backedges);
    }
}

def make_method(name: str) -> Method {
    method = Method(name=name);
    return method;
}

def add_call(caller: Method, callee: Method) -> None {
    caller +>:Calls:+> callee;
}

def make_call_graph(entry: Method) -> CallGraph {
    graph = CallGraph(entry=entry);
    return graph;
}
