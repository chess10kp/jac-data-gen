node GraphRoot {
    has label: str;
}
node Principal {
    has pid: str;
    has kind: str;
}
node Namespace {
    has nid: str;
    has name: str;
    has owner_pid: str;
}
node Resource {
    has rid: str;
    has namespace_id: str;
}
node Role {
    has name: str;
    has action: str;
    has scope: str;
}
node Assignment {
    has expires_at: int = 0;
}
edge HasPrincipal {}
edge HasNamespace {}
edge HasResource {}
edge HasRole {}
edge Assigned {}
edge UsesRole {}
edge Child {}
edge MemberOf {}

obj Registry {
    has graph_root: GraphRoot;
    has now: int;
    has default_allow: bool;
    has restrictive_scopes: list[str];
}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can walk with Namespace entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        self.found.append(here.nid);
        print(here.nid);
        for kid in [here ->:Child:->][?:Namespace] {
            visit :0: [kid];
        }
    }
}

walker AuthorizationWalker {
    has registry: Registry;
    has action: str;
    has scope: str;
    has allowed: bool = False;
    has claimed: dict[str, bool] = {};

    can inspect with Principal entry {
        if here.pid in self.claimed {
            skip;
        }
        self.claimed[here.pid] = True;
        print(here.pid);
        for assignment in [here ->:Assigned:->][?:Assignment] {
            if assignment.expires_at == 0 or assignment.expires_at > self.registry.now {
                for role in [assignment ->:UsesRole:->][?:Role] {
                    if (role.action == self.action or role.action == "manage") and
                       (role.scope == self.scope or role.scope == "*") {
                        self.allowed = True;
                    }
                }
            }
        }
        for group in [here ->:MemberOf:->][?:Principal] {
            visit :0: [group];
        }
    }
}

def find_principal(registry: Registry, pid: str) -> Principal | None {
    for item in [registry.graph_root ->:HasPrincipal:->][?:Principal] {
        if item.pid == pid {
            return item;
        }
    }
    return None;
}

def find_namespace(registry: Registry, nid: str) -> Namespace | None {
    for item in [registry.graph_root ->:HasNamespace:->][?:Namespace] {
        if item.nid == nid {
            return item;
        }
    }
    return None;
}

def find_resource(registry: Registry, rid: str) -> Resource | None {
    for item in [registry.graph_root ->:HasResource:->][?:Resource] {
        if item.rid == rid {
            return item;
        }
    }
    return None;
}

def find_role(registry: Registry, name: str) -> Role | None {
    for item in [registry.graph_root ->:HasRole:->][?:Role] {
        if item.name == name {
            return item;
        }
    }
    return None;
}

def new_registry() -> Registry {
    graph_root = GraphRoot(label="rbac");
    return Registry(graph_root=graph_root, now=100, default_allow=True,
                    restrictive_scopes=[]);
}

def register_principal(registry: Registry, pid: str,
                       kind: str = "user") -> Principal {
    existing = find_principal(registry, pid);
    if existing != None {
        return existing;
    }
    principal = Principal(pid=pid, kind=kind);
    registry.graph_root +>:HasPrincipal:+> principal;
    return principal;
}

def add_member(registry: Registry, member_id: str, group_id: str) -> bool {
    member = find_principal(registry, member_id);
    group = find_principal(registry, group_id);
    if member == None or group == None or group.kind != "group" {
        return False;
    }
    member +>:MemberOf:+> group;
    return True;
}

def grant_access(registry: Registry, principal_id: str, action: str,
                 scope: str, expires_at: int = 0) -> bool {
    principal = find_principal(registry, principal_id);
    if principal == None {
        return False;
    }
    role_name = action + "@" + scope;
    role = find_role(registry, role_name);
    if role == None {
        role = Role(name=role_name, action=action, scope=scope);
        registry.graph_root +>:HasRole:+> role;
    }
    assignment = Assignment(expires_at=expires_at);
    registry.graph_root +>:HasPrincipal:+> assignment;
    principal +>:Assigned:+> assignment;
    assignment +>:UsesRole:+> role;
    return True;
}

def add_namespace(registry: Registry, nid: str, name: str,
                  owner_pid: str, parent_id: str | None = None) -> Namespace | None {
    owner = find_principal(registry, owner_pid);
    if owner == None {
        return None;
    }
    if parent_id != None and find_namespace(registry, parent_id) == None {
        return None;
    }
    namespace = Namespace(nid=nid, name=name, owner_pid=owner_pid);
    registry.graph_root +>:HasNamespace:+> namespace;
    if parent_id != None {
        parent = find_namespace(registry, parent_id);
        if parent != None {
            parent +>:Child:+> namespace;
        }
    }
    grant_access(registry, owner_pid, "manage", "namespace:" + nid);
    return namespace;
}

def add_resource(registry: Registry, rid: str,
                 namespace_id: str) -> Resource | None {
    if find_namespace(registry, namespace_id) == None {
        return None;
    }
    resource = Resource(rid=rid, namespace_id=namespace_id);
    registry.graph_root +>:HasResource:+> resource;
    return resource;
}

def explicit_access(registry: Registry, principal_id: str,
                    action: str, scope: str) -> bool {
    principal = find_principal(registry, principal_id);
    if principal == None {
        return False;
    }
    if principal.kind == "admin" {
        return True;
    }
    w = principal spawn AuthorizationWalker(registry=registry, action=action,
                                            scope=scope, claimed={});
    return w.allowed;
}

def can_access(registry: Registry, principal_id: str, action: str,
               resource_id: str) -> bool {
    principal = find_principal(registry, principal_id);
    resource = find_resource(registry, resource_id);
    if principal == None or resource == None {
        return False;
    }
    if action == "read" or action == "execute" or principal.kind == "admin" {
        return True;
    }
    node_scope = "node:" + resource_id;
    namespace_scope = "namespace:" + resource.namespace_id;
    if explicit_access(registry, principal_id, action, node_scope) or
       explicit_access(registry, principal_id, action, namespace_scope) {
        return True;
    }
    for restricted in registry.restrictive_scopes {
        if restricted == node_scope or restricted == namespace_scope {
            return False;
        }
    }
    return registry.default_allow;
}

def delegate_namespace(registry: Registry, actor_id: str, target_id: str,
                       subject_id: str, action: str, scope: str,
                       expires_at: int = 0) -> bool {
    if find_namespace(registry, target_id) == None or
       find_principal(registry, subject_id) == None {
        return False;
    }
    if not explicit_access(registry, actor_id, "manage",
                           "namespace:" + target_id) {
        return False;
    }
    if not explicit_access(registry, actor_id, "manage", scope) {
        return False;
    }
    return grant_access(registry, subject_id, action, scope, expires_at);
}

def reachable_namespaces(registry: Registry, start_id: str) -> list[str] {
    start = find_namespace(registry, start_id);
    if start == None {
        return [];
    }
    w = start spawn ReachWalker(claimed={});
    return sorted(w.found);
}

test "diamond revisit is once only" {
    registry = new_registry();
    register_principal(registry, "owner");
    a = add_namespace(registry, "a", "A", "owner");
    b = add_namespace(registry, "b", "B", "owner", "a");
    d = add_namespace(registry, "d", "D", "owner", "a");
    assert (a != None and b != None and d != None);
    if a != None and b != None and d != None {
        b +>:Child:+> d;
    }
    assert (reachable_namespaces(registry, "a") == ["a", "b", "d"]);
}

test "unknown identifiers are tolerated" {
    registry = new_registry();
    assert (find_principal(registry, "missing") == None);
    assert (add_resource(registry, "r", "missing") == None);
    assert (can_access(registry, "missing", "write", "r") == False);
    assert (delegate_namespace(registry, "missing", "n", "u",
                               "write", "node:r") == False);
}

test "namespace creation assigns ownership and expiry is enforced" {
    registry = new_registry();
    registry.default_allow = False;
    register_principal(registry, "owner");
    register_principal(registry, "viewer");
    add_namespace(registry, "sales", "Sales", "owner");
    add_resource(registry, "orders", "sales");
    assert (can_access(registry, "owner", "write", "orders") == True);
    grant_access(registry, "viewer", "write", "node:orders", 90);
    assert (can_access(registry, "viewer", "write", "orders") == False);
}

test "group grants survive a membership cycle" {
    registry = new_registry();
    registry.default_allow = False;
    register_principal(registry, "group", "group");
    register_principal(registry, "member");
    register_principal(registry, "owner");
    add_namespace(registry, "n", "N", "owner");
    add_resource(registry, "r", "n");
    add_member(registry, "member", "group");
    add_member(registry, "group", "group");
    grant_access(registry, "group", "write", "node:r");
    assert (can_access(registry, "member", "write", "r") == True);
}

test "delegation requires explicit manage scopes" {
    registry = new_registry();
    registry.default_allow = False;
    register_principal(registry, "owner");
    register_principal(registry, "subject");
    add_namespace(registry, "n", "N", "owner");
    add_resource(registry, "r", "n");
    assert (delegate_namespace(registry, "owner", "n", "subject",
                               "write", "node:r") == False);
    grant_access(registry, "owner", "manage", "node:r");
    assert (delegate_namespace(registry, "owner", "n", "subject",
                               "write", "node:r") == True);
    assert (can_access(registry, "subject", "write", "r") == True);
}
