"""UnitOneAI/SecuritySkills#2776 — ReBAC cycle and deny-edge gates."""

node Principal {
    has name: str;
}

node Resource {
    has name: str;
}

edge Member {}
edge Parent {}
edge Permit {}
edge Deny {}

obj AuthzGraph {
    has principals: dict[str, Principal] = {};
    has resources: dict[str, Resource] = {};
}

walker PrincipalWalk {
    has claimed: dict[str, bool] = {};
    has found: dict[str, bool] = {};
    has levels: dict[str, int] = {};
    has max_depth: int = 8;

    can step with Principal entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid not in self.levels { self.levels[here.cid] = 0; }
        self.found[here.name] = True;
        print(here.name);
        current_level: int = self.levels[here.cid];
        if current_level < self.max_depth {
            next_level: int = current_level + 1;
            for parent in [here ->:Member:->][?:Principal] {
                if parent.cid not in self.levels {
                    self.levels[parent.cid] = next_level;
                }
                visit :0: [parent];
            }
        }
    }
}

walker ResourceWalk {
    has claimed: dict[str, bool] = {};
    has denied: dict[str, bool] = {};
    has granted: dict[str, bool] = {};
    has levels: dict[str, int] = {};
    has max_depth: int = 8;

    can step with Resource entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid not in self.levels { self.levels[here.cid] = 0; }
        print(here.name);
        for principal in [here ->:Deny:->][?:Principal] {
            self.denied[principal.name] = True;
        }
        for principal in [here ->:Permit:->][?:Principal] {
            self.granted[principal.name] = True;
        }
        current_level: int = self.levels[here.cid];
        if current_level < self.max_depth {
            next_level: int = current_level + 1;
            for parent in [here ->:Parent:->][?:Resource] {
                if parent.cid not in self.levels {
                    self.levels[parent.cid] = next_level;
                }
                visit :0: [parent];
            }
        }
    }
}

def new_graph() -> AuthzGraph {
    return AuthzGraph();
}

def add_principal(graph: AuthzGraph, principal_id: str) -> bool {
    if principal_id in graph.principals { return False; }
    graph.principals[principal_id] = Principal(name=principal_id);
    return True;
}

def add_resource(graph: AuthzGraph, resource_id: str) -> bool {
    if resource_id in graph.resources { return False; }
    graph.resources[resource_id] = Resource(name=resource_id);
    return True;
}

def add_member(graph: AuthzGraph, member_id: str, group_id: str) -> bool {
    if member_id not in graph.principals { return False; }
    if group_id not in graph.principals { return False; }
    graph.principals[member_id] +>:Member:+> graph.principals[group_id];
    return True;
}

def add_parent(graph: AuthzGraph, child_id: str, parent_id: str) -> bool {
    if child_id not in graph.resources { return False; }
    if parent_id not in graph.resources { return False; }
    graph.resources[child_id] +>:Parent:+> graph.resources[parent_id];
    return True;
}

def add_grant(graph: AuthzGraph, principal_id: str, resource_id: str) -> bool {
    if principal_id not in graph.principals { return False; }
    if resource_id not in graph.resources { return False; }
    graph.resources[resource_id] +>:Permit:+> graph.principals[principal_id];
    return True;
}

def add_deny(graph: AuthzGraph, principal_id: str, resource_id: str) -> bool {
    if principal_id not in graph.principals { return False; }
    if resource_id not in graph.resources { return False; }
    graph.resources[resource_id] +>:Deny:+> graph.principals[principal_id];
    return True;
}

def is_allowed(
    graph: AuthzGraph,
    principal_id: str,
    resource_id: str,
    max_depth: int = 8
) -> bool {
    if principal_id not in graph.principals { return False; }
    if resource_id not in graph.resources { return False; }
    subject = graph.principals[principal_id];
    principals = subject spawn PrincipalWalk(
        claimed={}, levels={}, max_depth=max_depth
    );
    target = graph.resources[resource_id];
    resources = target spawn ResourceWalk(
        claimed={}, levels={}, denied={}, granted={}, max_depth=max_depth
    );
    for candidate in principals.found.keys() {
        if candidate in resources.denied { return False; }
    }
    for candidate in principals.found.keys() {
        if candidate in resources.granted { return True; }
    }
    return False;
}
