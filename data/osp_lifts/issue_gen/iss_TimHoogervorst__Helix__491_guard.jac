# iss_TimHoogervorst__Helix__491.jac

node Catalog {
    has id: str;
}
node User {
    has id: str;
}
node Project {
    has id: str;
}
node AccessScope {
    has id: str;
    has owner_project_id: str;
    has kind: str;
    has root_folder_id: str = "";
}
node Item {
    has id: str;
    has parent_id: str;
    has owner_project_id: str;
    has access_scope_id: str;
    has is_folder: bool = False;
}
node AccessGrant {
    has scope_id: str;
    has principal_type: str;
    has principal_id: str;
    has role: str;
}

edge CatalogProject {}
edge ProjectMember {}
edge ProjectItem {}
edge ProjectScope {}
edge Child {}
edge ItemScope {}
edge ScopeGrant {}

walker ItemSearch {
    has wanted_id: str;
    has found: Item | None = None;
    has claimed: dict[str, bool] = {};

    can scan_catalog with Catalog entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        for project in [here ->:CatalogProject:->][?:Project] {
            visit project;
        }
        print("scan catalog");
    }

    can scan_project with Project entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        for item in [here ->:ProjectItem:->][?:Item] {
            visit item;
        }
        print("scan project");
    }

    can scan_item with Item entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        if here.id == self.wanted_id {
            self.found = here;
        }
        for child in [here ->:Child:->][?:Item] {
            visit :0: [child];
        }
        print("scan item");
    }
}

walker ProjectMemberSearch {
    has user_id: str;
    has project_id: str;
    has found: bool = False;
    has claimed: dict[str, bool] = {};

    can inspect_catalog with Catalog entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        for project in [here ->:CatalogProject:->][?:Project] {
            visit project;
        }
        print("inspect catalog");
    }

    can inspect_project with Project entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        if here.id == self.project_id {
            for member in [here ->:ProjectMember:->][?:User] {
                if member.id == self.user_id {
                    self.found = True;
                }
            }
        }
        print("inspect project");
    }
}

def role_allows(granted: str, required: str) -> bool {
    if granted == "ADMIN" {
        return required == "READ" or required == "WRITE" or required == "ADMIN";
    }
    if granted == "WRITE" {
        return required == "READ" or required == "WRITE";
    }
    if granted == "READ" {
        return required == "READ";
    }
    return False;
}

def find_item(graph_root: Catalog, item_id: str) -> Item | None {
    w = graph_root spawn ItemSearch(wanted_id=item_id);
    return w.found;
}

def has_project_member(
    graph_root: Catalog, user_id: str, project_id: str
) -> bool {
    w = graph_root spawn ProjectMemberSearch(
        user_id=user_id, project_id=project_id
    );
    return w.found;
}

def has_project_permission(
    graph_root: Catalog, user_id: str, project_id: str, permission: str
) -> bool {
    return has_project_member(graph_root, user_id, project_id);
}

def has_scope_permission(
    graph_root: Catalog, user_id: str, scope: AccessScope, permission: str
) -> bool {
    for grant in [scope ->:ScopeGrant:->][?:AccessGrant] {
        if grant.principal_type == "USER" {
            if grant.principal_id == user_id
                and role_allows(grant.role, permission) {
                return True;
            }
        } else if grant.principal_type == "PROJECT" {
            if has_project_member(graph_root, user_id, grant.principal_id)
                and role_allows(grant.role, permission) {
                return True;
            }
        }
    }
    return False;
}

def can_access(
    graph_root: Catalog, user_id: str, item_id: str, permission: str
) -> bool {
    item = find_item(graph_root, item_id);
    if item is None {
        return False;
    }
    if has_project_permission(
        graph_root, user_id, item.owner_project_id, permission
    ) {
        return True;
    }
    for scope in [item ->:ItemScope:->][?:AccessScope] {
        if has_scope_permission(graph_root, user_id, scope, permission) {
            return True;
        }
    }
    return False;
}

test "diamond revisit preserves later visits" {
    graph = Catalog(id="catalog");
    project_a = Project(id="project-a");
    user_a = User(id="user-a");
    graph +>:CatalogProject:+> project_a;
    project_a +>:ProjectMember:+> user_a;

    scope = AccessScope(
        id="scope-x",
        owner_project_id="project-a",
        kind="FOLDER",
        root_folder_id="folder-x"
    );
    project_a +>:ProjectScope:+> scope;

    folder = Item(
        id="folder-x",
        parent_id="",
        owner_project_id="project-a",
        access_scope_id="scope-x",
        is_folder=True
    );
    left = Item(
        id="left",
        parent_id="folder-x",
        owner_project_id="project-a",
        access_scope_id="scope-x"
    );
    right = Item(
        id="right",
        parent_id="folder-x",
        owner_project_id="project-a",
        access_scope_id="scope-x"
    );
    shared = Item(
        id="shared",
        parent_id="left",
        owner_project_id="project-a",
        access_scope_id="scope-x"
    );
    tail = Item(
        id="tail",
        parent_id="right",
        owner_project_id="project-a",
        access_scope_id="scope-x"
    );
    project_a +>:ProjectItem:+> folder;
    folder +>:ItemScope:+> scope;
    folder +>:Child:+> left;
    folder +>:Child:+> right;
    left +>:Child:+> shared;
    right +>:Child:+> tail;
    right +>:Child:+> shared;
    shared +>:ItemScope:+> scope;
    tail +>:ItemScope:+> scope;

    grant = AccessGrant(
        scope_id="scope-x",
        principal_type="USER",
        principal_id="user-a",
        role="WRITE"
    );
    scope +>:ScopeGrant:+> grant;

    assert (find_item(graph, "shared") is not None);
    assert (find_item(graph, "tail") is not None);
    assert (has_project_member(graph, "user-a", "project-a"));
    assert (has_project_permission(graph, "user-a", "project-a", "ADMIN"));
    assert (has_scope_permission(graph, "user-a", scope, "WRITE"));
    assert (can_access(graph, "user-a", "tail", "WRITE"));
}

test "project sharing grants only its role" {
    graph = Catalog(id="catalog");
    project_a = Project(id="project-a");
    project_b = Project(id="project-b");
    user_b = User(id="user-b");
    graph +>:CatalogProject:+> project_a;
    graph +>:CatalogProject:+> project_b;
    project_b +>:ProjectMember:+> user_b;

    scope = AccessScope(
        id="scope-shared",
        owner_project_id="project-a",
        kind="FOLDER",
        root_folder_id="folder"
    );
    project_a +>:ProjectScope:+> scope;
    folder = Item(
        id="folder",
        parent_id="",
        owner_project_id="project-a",
        access_scope_id="scope-shared",
        is_folder=True
    );
    project_a +>:ProjectItem:+> folder;
    folder +>:ItemScope:+> scope;

    grant = AccessGrant(
        scope_id="scope-shared",
        principal_type="PROJECT",
        principal_id="project-b",
        role="READ"
    );
    scope +>:ScopeGrant:+> grant;

    assert (has_scope_permission(graph, "user-b", scope, "READ"));
    assert (can_access(graph, "user-b", "folder", "READ"));
    assert (can_access(graph, "user-b", "folder", "WRITE") == False);
}

test "unknown identifiers and role boundaries are safe" {
    graph = Catalog(id="empty");
    scope = AccessScope(
        id="scope-empty",
        owner_project_id="missing-project",
        kind="PROJECT"
    );

    assert (find_item(graph, "missing-item") is None);
    assert (has_project_member(graph, "missing-user", "missing-project") == False);
    assert (
        has_project_permission(
            graph, "missing-user", "missing-project", "READ"
        ) == False
    );
    assert (
        has_scope_permission(graph, "missing-user", scope, "READ") == False
    );
    assert (
        can_access(graph, "missing-user", "missing-item", "READ") == False
    );
    assert (role_allows("ADMIN", "READ"));
    assert (role_allows("WRITE", "READ"));
    assert (role_allows("WRITE", "ADMIN") == False);
    assert (role_allows("UNKNOWN", "READ") == False);
}
