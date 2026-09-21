"""Effective permissions through role inheritance.

Roles grant permissions directly via Grants edges and inherit more from
parent roles via InheritsFrom edges. A resolver walker starting at a
user's role walks up the inheritance chain, unioning every granted action
into one deduplicated set, and reports the sorted effective permissions
when it exits the role it started from.
"""

node Permission {
    has action: str;
}

node Role {
    has title: str;
}

edge InheritsFrom: Role --> Role {}

edge Grants: Role --> Permission {}

walker PermissionResolver {
    has visited: list[str] = [];
    has effective: list[str] = [];
    has base_role: str = "";

    can resolve with Role entry {
        if here.title in self.visited {
            skip;  # diamond-shaped inheritance: already merged this branch
        }
        if self.base_role == "" {
            self.base_role = here.title;
        }
        self.visited.append(here.title);

        for perm in [->:Grants:->] {
            act = perm.action;
            if act not in self.effective {
                self.effective.append(act);
            }
        }
        visit [->:InheritsFrom:->];  # climb toward parent roles
    }

    can summarize with Role exit {
        # Deferred exits mean this fires at the starting role only after
        # every inherited branch above it has been fully merged.
        if here.title == self.base_role {
            self.effective.sort();
            print(f"Effective permissions for '{self.base_role}' "
                  f"({len(self.visited)} roles consulted):");
            for act in self.effective {
                print(f"  - {act}");
            }
        }
    }
}

with entry {

    # Reset leftovers from any previous run of this demo.
    for stale_node in [root -->][?:Role] {
        del stale_node;
    }
    for stale_node in [root -->][?:Permission] {
        del stale_node;
    }
    viewer = Role(title="viewer");
    editor = Role(title="editor");
    publisher = Role(title="publisher");
    admin = Role(title="admin");

    can_read = Permission(action="doc:read");
    can_comment = Permission(action="doc:comment");
    can_edit = Permission(action="doc:edit");
    can_publish = Permission(action="doc:publish");
    can_manage = Permission(action="user:manage");

    viewer +>: Grants() :+> can_read;
    editor +>: Grants() :+> can_comment;
    editor +>: Grants() :+> can_edit;
    publisher +>: Grants() :+> can_publish;
    admin +>: Grants() :+> can_manage;

    # admin inherits publisher, which inherits editor, which inherits viewer.
    admin +>: InheritsFrom() :+> publisher;
    publisher +>: InheritsFrom() :+> editor;
    editor +>: InheritsFrom() :+> viewer;
    # A shortcut edge creating a diamond: admin also inherits viewer.
    admin +>: InheritsFrom() :+> viewer;

    admin spawn PermissionResolver();
}
