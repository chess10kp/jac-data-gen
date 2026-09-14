"""SEI-Mkittok/omnir-refactor#304: tenant-scoped role hierarchy."""

node Role {
    has role_id: str;
    has name: str;
    has tenant_id: str;
    has parent_id: str | None = None;
    has sort_order: int = 0;
    has archived: bool = False;
    has descendant_access: bool = False;
}

edge RoleParent {}

obj RoleBook {
    has tenant_id: str;
    has roles: dict[str, Role] = {};
    has role_ids: list[str] = [];
    has graph_root: Role | None = None;
}

walker DescendantWalker {
    has claimed: dict[str, bool] = {};
    has found: list[Role] = [];

    can collect with Role entry {
        if here.role_id in self.claimed { skip; }
        self.claimed[here.role_id] = True;
        self.found.append(here);
        print here.role_id;
        for child in [here ->:RoleParent:->][?:Role] {
            visit :0: [child];
        }
    }
}

def new_book(tenant_id: str) -> RoleBook {
    organization = Role(
        role_id="organization",
        name="Organization",
        tenant_id=tenant_id
    );
    book = RoleBook(tenant_id=tenant_id);
    book.graph_root = organization;
    book.roles["organization"] = organization;
    book.role_ids.append("organization");
    return book;
}

def create_role(
    book: RoleBook,
    role_id: str,
    name: str,
    tenant_id: str,
    parent_id: str | None = None,
    sort_order: int = 0
) -> bool {
    if tenant_id != book.tenant_id or role_id in book.roles { return False; }
    parent_node: Role | None = book.graph_root;
    if parent_id != None {
        if parent_id not in book.roles { return False; }
        parent_node = book.roles[parent_id];
    }
    if parent_node == None or parent_node.tenant_id != tenant_id {
        return False;
    }
    role_node = Role(
        role_id=role_id,
        name=name,
        tenant_id=tenant_id,
        parent_id=parent_node.role_id,
        sort_order=sort_order
    );
    parent_node +>:RoleParent:+> role_node;
    book.roles[role_id] = role_node;
    book.role_ids.append(role_id);
    return True;
}

def descendants(book: RoleBook, role_id: str) -> list[str] {
    ids: list[str] = [];
    if role_id not in book.roles { return ids; }
    claims: dict[str, bool] = {};
    w = book.roles[role_id] spawn DescendantWalker(claimed=claims);
    for item in w.found {
        if item.role_id != role_id { ids.append(item.role_id); }
    }
    return sorted(ids);
}

def move_role(
    book: RoleBook,
    role_id: str,
    new_parent_id: str | None,
    tenant_id: str
) -> bool {
    if role_id not in book.roles or tenant_id != book.tenant_id {
        return False;
    }
    role_node = book.roles[role_id];
    if role_node.archived or role_id == "organization" {
        return False;
    }
    parent_node: Role | None = book.graph_root;
    if new_parent_id != None {
        if new_parent_id not in book.roles { return False; }
        parent_node = book.roles[new_parent_id];
        for child_id in descendants(book, role_id) {
            if child_id == new_parent_id { return False; }
        }
    }
    if parent_node == None or parent_node.archived {
        return False;
    }
    if role_node.parent_id != None {
        old_parent = book.roles[role_node.parent_id];
        old_parent -:RoleParent:-> role_node;
    }
    parent_node +>:RoleParent:+> role_node;
    role_node.parent_id = parent_node.role_id;
    return True;
}

def rename_role(book: RoleBook, role_id: str, name: str) -> bool {
    if role_id not in book.roles or book.roles[role_id].archived {
        return False;
    }
    book.roles[role_id].name = name;
    return True;
}

def reorder_role(book: RoleBook, role_id: str, sort_order: int) -> bool {
    if role_id not in book.roles or book.roles[role_id].archived {
        return False;
    }
    book.roles[role_id].sort_order = sort_order;
    return True;
}

def set_descendant_access(book: RoleBook, role_id: str, enabled: bool) -> bool {
    if role_id not in book.roles or book.roles[role_id].archived {
        return False;
    }
    book.roles[role_id].descendant_access = enabled;
    return True;
}

def archive_role(book: RoleBook, role_id: str) -> bool {
    if role_id not in book.roles or role_id == "organization" {
        return False;
    }
    book.roles[role_id].archived = True;
    return True;
}

def permission_scope(book: RoleBook, role_id: str) -> list[str] {
    scope: list[str] = [];
    if role_id not in book.roles or book.roles[role_id].archived {
        return scope;
    }
    role_node = book.roles[role_id];
    scope.append(role_id);
    if role_node.descendant_access {
        for child_id in descendants(book, role_id) {
            if not book.roles[child_id].archived { scope.append(child_id); }
        }
    }
    return sorted(scope);
}

def hierarchy(book: RoleBook) -> list[Role] {
    rows: list[Role] = [];
    for role_id in sorted(book.role_ids) {
        rows.append(book.roles[role_id]);
    }
    return rows;
}

test "diamond revisit is claimed once" {
    book = new_book("tenant-a");
    assert (create_role(book, "a", "A", "tenant-a", "organization", 1));
    assert (create_role(book, "b", "B", "tenant-a", "organization", 2));
    assert (create_role(book, "c", "C", "tenant-a", "a", 1));
    book.roles["b"] +>:RoleParent:+> book.roles["c"];
    assert (descendants(book, "organization") == ["a", "b", "c"]);
}

test "unknown ids are tolerated" {
    book = new_book("tenant-a");
    assert (descendants(book, "missing") == []);
    assert (permission_scope(book, "missing") == []);
    assert (move_role(book, "missing", None, "tenant-a") == False);
    assert (rename_role(book, "missing", "Nope") == False);
}

test "moves reject cycles and preserve root moves" {
    book = new_book("tenant-a");
    assert (create_role(book, "exec", "Exec", "tenant-a"));
    assert (create_role(book, "ops", "Operations", "tenant-a", "exec"));
    assert (move_role(book, "exec", "ops", "tenant-a") == False);
    assert (move_role(book, "ops", None, "tenant-a"));
    assert (book.roles["ops"].parent_id == "organization");
    assert (move_role(book, "ops", "missing", "tenant-a") == False);
}

test "scope follows descendant authority only" {
    book = new_book("tenant-a");
    assert (create_role(book, "exec", "Exec", "tenant-a"));
    assert (create_role(book, "sales", "Sales", "tenant-a", "exec"));
    assert (create_role(book, "ops", "Operations", "tenant-a", "exec"));
    assert (permission_scope(book, "exec") == ["exec"]);
    assert (set_descendant_access(book, "exec", True));
    assert (permission_scope(book, "exec") == ["exec", "ops", "sales"]);
    assert (archive_role(book, "ops"));
    assert (permission_scope(book, "exec") == ["exec", "sales"]);
}

test "tenant and system-root protections hold" {
    book = new_book("tenant-a");
    assert (create_role(book, "exec", "Exec", "tenant-b") == False);
    assert (archive_role(book, "organization") == False);
    assert (move_role(book, "organization", None, "tenant-a") == False);
    assert (reorder_role(book, "organization", 4));
}
