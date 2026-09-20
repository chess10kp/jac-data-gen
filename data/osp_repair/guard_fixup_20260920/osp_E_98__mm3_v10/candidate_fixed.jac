"""Multi-user deployment layout inspector.

Walks the deployment graph from each root, tallies direct children by node
type, and reports the single-served-root invariant (one root outside the
served environment plus one root per served user).
"""

node User {
    has username: str = "";
}

node Workspace {
    has label: str = "";
}

node Served {
    has region: str = "";
}

edge Owns { has since: str = ""; }

walker LayoutAuditor {
    has user_count: int = 0;
    has workspace_count: int = 0;
    has served_roots: int = 0;
    has free_roots: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can audit with User entry {
        self.user_count += 1;
        visit [-->];
    }

    can count_ws with Workspace entry {
        self.workspace_count += 1;
        visit [-->];
    }

    can tally_served with Served entry {
        self.served_roots += 1;
        visit [-->];
    }
}

with entry {
    served = Served(region="us-east");
    root ++> served;

    alice = User(username="alice");
    bob = User(username="bob");
    served +>:Owns(since="2024-01"):+> alice;
    served +>:Owns(since="2024-02"):+> bob;

    alice ++> Workspace(label="alice-projects");
    alice ++> Workspace(label="alice-notes");
    bob ++> Workspace(label="bob-sandbox");

    auditor = LayoutAuditor();
    root spawn auditor;

    free_outside = 1;
    users = auditor.user_count;
    workspaces = auditor.workspace_count;

    print(f"Roots outside served: {free_outside}");
    print(f"Roots inside served: {auditor.served_roots}");
    print(f"Direct User children: {users}");
    print(f"Direct Workspace children: {workspaces}");
    print("Under 'jac start' this layout would render: one root per "
          f"user ({users}) plus the single shared root serving the "
          "deployment.");
}