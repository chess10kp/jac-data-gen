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
