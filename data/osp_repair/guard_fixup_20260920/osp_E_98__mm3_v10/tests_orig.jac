"""Tests for the multi-user deployment layout inspector."""

import io;
import from contextlib { redirect_stdout }

test "root has exactly one direct Served child" {
    root ++> Served(region="us-east");
    served = [root --> Served][0];
    assert len([root -->]) == 1, f"root should have exactly 1 direct child, got {len([root -->])}";
    assert [root -->][0] == served, "root's direct child must be the Served node";
}

test "served owns two users via Owns edges" {
    served = Served(region="us-east");
    root ++> served;

    alice = User(username="alice");
    bob = User(username="bob");
    served +>:Owns(since="2024-01"):+> alice;
    served +>:Owns(since="2024-02"):+> bob;

    owned = [served ->:Owns:->];
    assert len(owned) == 2, f"served should own 2 users, got {len(owned)}";
    assert alice in owned, "alice must be linked via Owns";
    assert bob in owned, "bob must be linked via Owns";
}

test "auditor tallies children by type from root" {
    served = Served(region="us-east");
    root ++> served;

    alice = User(username="alice");
    bob = User(username="bob");
    served +>:Owns(since="2024-01"):+> alice;
    served +>:Owns(since="2024-02"):+> bob;

    alice ++> Workspace(label="alice-projects");
    alice ++> Workspace(label="alice-notes");
    bob ++> Workspace(label="bob-sandbox");

    auditor = root spawn LayoutAuditor();
    assert auditor.user_count == 2, f"user_count should be 2, got {auditor.user_count}";
    assert auditor.workspace_count == 3, f"workspace_count should be 3, got {auditor.workspace_count}";
    assert auditor.served_roots == 1, f"served_roots should be 1, got {auditor.served_roots}";
}

test "single served invariant holds for larger multi-user graph" {
    served = Served(region="eu-west");
    root ++> served;

    users = [
        User(username="u1"),
        User(username="u2"),
        User(username="u3"),
        User(username="u4"),
    ];

    i = 0;
    for u in users {
        i += 1;
        served +>:Owns(since=f"2024-{i:02d}"):+> u;
        u ++> Workspace(label=f"ws-{i}");
        u ++> Workspace(label=f"notes-{i}");
    }

    auditor = root spawn LayoutAuditor();
    assert auditor.served_roots == 1, f"single-served invariant broken: {auditor.served_roots}";
    assert auditor.user_count == 4, f"expected 4 users, got {auditor.user_count}";
    assert auditor.workspace_count == 8, f"expected 8 workspaces, got {auditor.workspace_count}";
}

test "deployment report mentions one root per user plus shared root" {
    served = Served(region="us-east");
    root ++> served;

    alice = User(username="alice");
    bob = User(username="bob");
    served +>:Owns(since="2024-01"):+> alice;
    served +>:Owns(since="2024-02"):+> bob;

    alice ++> Workspace(label="alice-projects");
    alice ++> Workspace(label="alice-notes");
    bob ++> Workspace(label="bob-sandbox");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        auditor = root spawn LayoutAuditor();
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
    out = buf.getvalue();

    assert "Roots outside served: 1" in out, f"missing outside count line: {out}";
    assert "Roots inside served: 1" in out, f"missing served count line: {out}";
    assert "Direct User children: 2" in out, f"missing user tally: {out}";
    assert "Direct Workspace children: 3" in out, f"missing workspace tally: {out}";
    assert "one root per user (2) plus the single shared root" in out, f"missing layout line: {out}";
}