"""Adamantine-guild/guildpass-core#379: deterministic permission inheritance."""

node Role {
    has id: str;
    has permissions: list[str] = [];
    has inherits: list[str] = [];
    has depth: int = 0;
}

edge Owns {}
edge Inherits {}

node RoleCatalog {
    has roles: list[Role] = [];
    has by_id: dict[str, Role] = {};
    has duplicate_ids: list[str] = [];
}

node PermissionResult {
    has ok: bool = True;
    has permissions: list[str] = [];
    has error_code: str = "";
    has error_role: str = "";
    has error_parent: str = "";
}

walker PermissionWalker {
    has catalog: RoleCatalog;
    has result: PermissionResult;
    has claimed: dict[str, bool] = {};
    has active: dict[str, bool] = {};
    has seen: dict[str, bool] = {};
    has visited_count: int = 0;
    has max_depth: int = 64;
    has max_roles: int = 1000;

    can resolve with Role entry {
        if here.id in self.claimed {
            if here.id in self.active {
                if self.result.error_code == "" {
                    self.result.ok = False;
                    self.result.error_code = "cycle";
                    self.result.error_role = here.id;
                }
            }
            skip;
        }
        self.claimed[here.id] = True;
        self.active[here.id] = True;
        self.visited_count += 1;
        print("resolve " + here.id);

        if self.visited_count > self.max_roles {
            self.result.ok = False;
            self.result.error_code = "graph_size";
            self.result.error_role = here.id;
        } elif here.depth > self.max_depth {
            self.result.ok = False;
            self.result.error_code = "depth_limit";
            self.result.error_role = here.id;
        } else {
            for permission in here.permissions {
                if permission not in self.seen {
                    self.seen[permission] = True;
                    self.result.permissions.append(permission);
                }
            }
            for parent_id in here.inherits {
                if parent_id not in self.catalog.by_id {
                    if self.result.error_code == "" {
                        self.result.ok = False;
                        self.result.error_code = "missing_parent";
                        self.result.error_role = here.id;
                        self.result.error_parent = parent_id;
                    }
                }
            }
            if self.result.error_code == "" {
                for parent in [here ->:Inherits:->][?:Role] {
                    parent.depth = here.depth + 1;
                    visit :0: [parent];
                }
            }
        }
        self.active[here.id] = False;
    }
}

def make_role(
    role_id: str,
    permissions: list[str] | None = None,
    inherits: list[str] | None = None
) -> Role {
    perms: list[str] = [];
    parents: list[str] = [];
    if permissions != None {
        for permission in permissions {
            perms.append(permission);
        }
    }
    if inherits != None {
        for parent_id in inherits {
            parents.append(parent_id);
        }
    }
    return Role(id=role_id, permissions=perms, inherits=parents);
}

def build_catalog(definitions: list[Role]) -> RoleCatalog {
    catalog = RoleCatalog();
    for definition in definitions {
        copied_permissions: list[str] = [];
        copied_parents: list[str] = [];
        for permission in definition.permissions {
            copied_permissions.append(permission);
        }
        for parent_id in definition.inherits {
            copied_parents.append(parent_id);
        }
        role_node = Role(
            id=definition.id,
            permissions=copied_permissions,
            inherits=copied_parents
        );
        catalog.roles.append(role_node);
        if role_node.id in catalog.by_id {
            catalog.duplicate_ids.append(role_node.id);
        } else {
            catalog.by_id[role_node.id] = role_node;
        }
        catalog +>:Owns:+> role_node;
    }
    for role_node in catalog.roles {
        for parent_id in role_node.inherits {
            if parent_id in catalog.by_id {
                parent: Role = catalog.by_id[parent_id];
                role_node +>:Inherits:+> parent;
            }
        }
    }
    return catalog;
}

def resolve_permission_result(
    definitions: list[Role],
    role_id: str,
    max_depth: int = 64,
    max_roles: int = 1000
) -> PermissionResult {
    result = PermissionResult();
    catalog = build_catalog(definitions);
    if len(catalog.duplicate_ids) > 0 {
        result.ok = False;
        result.error_code = "malformed";
        result.error_role = catalog.duplicate_ids[0];
        return result;
    }
    for role_node in catalog.roles {
        if role_node.id == "" {
            result.ok = False;
            result.error_code = "malformed";
            result.error_role = role_node.id;
            return result;
        }
    }
    if len(catalog.roles) > max_roles {
        result.ok = False;
        result.error_code = "graph_size";
        return result;
    }
    if role_id not in catalog.by_id {
        result.ok = False;
        result.error_code = "unknown_role";
        result.error_role = role_id;
        return result;
    }
    root_node: Role = catalog.by_id[role_id];
    root_node.depth = 0;
    w = root_node spawn PermissionWalker(
        catalog=catalog,
        result=result,
        claimed={},
        active={},
        seen={},
        visited_count=0,
        max_depth=max_depth,
        max_roles=max_roles
    );
    result.permissions = sorted(result.permissions);
    return result;
}

def resolve_permissions(
    definitions: list[Role],
    role_id: str,
    max_depth: int = 64,
    max_roles: int = 1000
) -> list[str] {
    result = resolve_permission_result(
        definitions,
        role_id,
        max_depth,
        max_roles
    );
    if result.ok {
        return result.permissions;
    }
    empty: list[str] = [];
    return empty;
}

test "direct_permissions_are_sorted_and_deduplicated" {
    roles: list[Role] = [];
    roles.append(make_role("member", ["write", "read", "read"]));
    roles.append(make_role("empty"));
    assert (sorted(resolve_permissions(roles, "member")) == ["read", "write"]);
    assert (resolve_permissions(roles, "empty") == []);
}

test "diamond_revisit_deduplicates_deterministically" {
    roles: list[Role] = [];
    roles.append(make_role("base", ["read", "read"]));
    roles.append(make_role("left", ["write", "read"], ["base"]));
    roles.append(make_role("right", ["audit", "write"], ["base"]));
    roles.append(make_role("top", ["admin"], ["right", "left"]));
    result = resolve_permission_result(roles, "top");
    assert (result.ok == True);
    assert (sorted(result.permissions) == ["admin", "audit", "read", "write"]);
}

test "cycles_are_reported_without_truncating_the_test" {
    roles: list[Role] = [];
    roles.append(make_role("a", ["alpha"], ["b"]));
    roles.append(make_role("b", ["beta"], ["a"]));
    result = resolve_permission_result(roles, "a");
    assert (result.ok == False);
    assert (result.error_code == "cycle");
}

test "unknown_role_and_missing_parent_are_tolerated" {
    roles: list[Role] = [];
    roles.append(make_role("child", ["read"], ["missing"]));
    unknown = resolve_permission_result(roles, "ghost");
    missing = resolve_permission_result(roles, "child");
    assert (unknown.ok == False);
    assert (unknown.error_code == "unknown_role");
    assert (resolve_permissions(roles, "ghost") == []);
    assert (missing.ok == False);
    assert (missing.error_code == "missing_parent");
    assert (missing.error_parent == "missing");
}

test "depth_and_graph_size_limits_are_enforced" {
    chain: list[Role] = [];
    chain.append(make_role("a", ["a"], ["b"]));
    chain.append(make_role("b", ["b"], ["c"]));
    chain.append(make_role("c", ["c"]));
    limited = resolve_permission_result(chain, "a", 1, 10);
    oversized = resolve_permission_result(chain, "a", 64, 2);
    assert (limited.error_code == "depth_limit");
    assert (oversized.error_code == "graph_size");
}
