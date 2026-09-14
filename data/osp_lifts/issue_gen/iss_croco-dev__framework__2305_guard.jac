# PROGRAM iss_croco-dev__framework__2305.jac

node Role {
    has role_id: str;
    has permissions: list[str] = [];
}

edge Inherits {}

obj DrizzleRoleRegistry {
    has roles: dict[str, Role] = {};
}

walker PermissionWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can collect with Role entry {
        if here.role_id in self.claimed {
            skip;
        }
        self.claimed[here.role_id] = True;
        print(here.role_id);

        for permission in here.permissions {
            if permission not in self.found {
                self.found.append(permission);
            }
        }

        for parent in [here ->:Inherits:->][?:Role] {
            visit :0: [parent];
        }
    }
}

def registerRole(
    registry: DrizzleRoleRegistry,
    role_id: str,
    permissions: list[str],
    inherits: list[str] | None = None
) -> None {
    role_node: Role = Role(role_id=role_id);
    if role_id in registry.roles {
        role_node = registry.roles[role_id];
    } else {
        registry.roles[role_id] = role_node;
    }

    role_node.permissions = permissions;
    inherited_ids: list[str] = [];
    if inherits is not None {
        inherited_ids = inherits;
    }

    for parent_id in inherited_ids {
        parent: Role = Role(role_id=parent_id);
        if parent_id in registry.roles {
            parent = registry.roles[parent_id];
        } else {
            registry.roles[parent_id] = parent;
        }
        role_node +>:Inherits:+> parent;
    }
}

def getRolePermissions(
    registry: DrizzleRoleRegistry,
    role_id: str
) -> list[str] {
    if role_id not in registry.roles {
        return [];
    }
    role_node: Role = registry.roles[role_id];
    w = role_node spawn PermissionWalker(claimed={});
    return sorted(w.found);
}

# TESTS

test "diamond inheritance deduplicates a revisit" {
    registry = DrizzleRoleRegistry();
    registerRole(registry, "base", ["read", "shared"], None);
    registerRole(registry, "leaf", ["leaf", "shared"], ["base"]);
    registerRole(registry, "left", ["left"], ["base", "leaf"]);
    registerRole(registry, "right", ["right", "shared"], ["leaf"]);
    registerRole(registry, "admin", ["manage", "shared"], ["left", "right"]);

    assert (
        getRolePermissions(registry, "admin")
        == ["leaf", "left", "manage", "read", "right", "shared"]
    );
}

test "unknown role returns an empty permission set" {
    registry = DrizzleRoleRegistry();

    assert (getRolePermissions(registry, "missing") == []);
}

test "direct role permissions remain available" {
    registry = DrizzleRoleRegistry();
    registerRole(registry, "editor", ["read", "write"], None);

    assert (getRolePermissions(registry, "editor") == ["read", "write"]);
}

test "cyclic inheritance terminates safely" {
    registry = DrizzleRoleRegistry();
    registerRole(registry, "alpha", ["alpha"], ["beta"]);
    registerRole(registry, "beta", ["beta"], ["alpha"]);

    assert (getRolePermissions(registry, "alpha") == ["alpha", "beta"]);
}
