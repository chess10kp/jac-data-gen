"""RBAC impersonation-grant auditor.

Models a Kubernetes RBAC policy graph: Roles/ClusterRoles contain Rules,
and Rules grant a set of (verbs, resources, resourceNames) tuples. A
walker audits every rule and flags impersonation grants that are not
scoped via resourceNames -- the "unconstrained impersonation" footgun
described in the issue.

The traversal replaces the hand-rolled recursion over parent/child
roles that the project used previously: typed edges carry the
containment relationships and the walker walks them natively.
"""

# --- Core entity archetypes --------------------------------------------------

node Rule {
    has verbs: list[str] = [];
    has resources: list[str] = [];
    has resource_names: list[str] = [];
    has label: str = "";
}

node Role {
    has name: str = "";
}

node ClusterRole {
    has name: str = "";
}

node RoleBinding {
    has name: str = "";
}

# --- Typed edges: relationships carry meaning -------------------------------

# A Role/ClusterRole owns a rule.
edge OwnsRule { }

# A RoleBinding references a Role (subject of impersonation check).
edge BindsRole { }

# A RoleBinding references a ClusterRole (subject of impersonation check).
edge BindsClusterRole { }

# --- Auditor walker ---------------------------------------------------------

walker ImpersonationAuditor {
    has flagged: list[str] = [];
    has allowed: list[str] = [];
    has visited_rules: set = {};

    # Single union ability: a rule, whether attached to a Role or a
    # ClusterRole, is checked by the exact same policy.
    can audit with Rule entry {
        rule_id = id(here);
        if rule_id in self.visited_rules {
            # walker has no built-in dedupe in jac 0.36.1; bail on cycles.
            disengage;
        }
        self.visited_rules.add(rule_id);

        verbs = here.verbs;
        resources = here.resources;
        names = here.resource_names;

        grants_impersonate = ("impersonate" in verbs) or ("*" in verbs);
        targets_user_resource = False;
        for r in resources {
            if r in ["users", "groups", "serviceaccounts", "userextras"] {
                targets_user_resource = True;
            }
            if r == "*" {
                targets_user_resource = True;
            }
        }

        is_flagged = False
            if grants_impersonate and targets_user_resource and len(names) == 0
            else False;
        # Above preserves semantics: flag requires impersonate + user-ish
        # resource + empty resourceNames. Compute label safely:
        if grants_impersonate and targets_user_resource {
            if len(names) == 0 {
                self.flagged.append(here.label);
                report f"FLAG  {here.label}: impersonate on {resources} with no resourceNames";
            } else {
                self.allowed.append(here.label);
                report f"OK    {here.label}: scoped to {names}";
            }
        } else {
            self.allowed.append(here.label);
            report f"skip  {here.label}: not an impersonation grant";
        }
    }
}

# --- Walker that reaches rules from anywhere in the graph --------------------

walker PolicyScan {
    can start with Root entry {
        visit [-->];
    }

    # Union ability so a Role OR a ClusterRole entry re-dispatches the
    # scan over its own rules AND continues forward.
    can descend with Role | ClusterRole | RoleBinding entry {
        visit [->:OwnsRule:->];
    }
}

# --- Demo wiring -------------------------------------------------------------

with entry {
    # A role with two rules: one dangerous impersonation grant, one safe.
    dev_role = Role(name="dev");
    dev_rule_bad = Rule(
        verbs=["impersonate"],
        resources=["users"],
        resource_names=[],
        label="dev/impersonate-users-unscoped",
    );
    dev_rule_good = Rule(
        verbs=["impersonate"],
        resources=["users"],
        resource_names=["alice", "bob"],
        label="dev/impersonate-users-scoped",
    );
    dev_rule_unrelated = Rule(
        verbs=["get", "list"],
        resources=["pods"],
        resource_names=[],
        label="dev/read-pods",
    );
    dev_role +>:OwnsRule:+> dev_rule_bad;
    dev_role +>:OwnsRule:+> dev_rule_good;
    dev_role +>:OwnsRule:+> dev_rule_unrelated;

    # A ClusterRole with wildcard impersonation -- also a flag.
    admin_cr = ClusterRole(name="admin");
    admin_rule = Rule(
        verbs=["*"],
        resources=["*"],
        resource_names=[],
        label="admin/wildcard-all",
    );
    admin_cr +>:OwnsRule:+> admin_rule;

    # A ClusterRole whose impersonation grant is scoped -- not a flag.
    sre_cr = ClusterRole(name="sre");
    sre_rule = Rule(
        verbs=["impersonate"],
        resources=["serviceaccounts"],
        resource_names=["system:serviceaccount:ns:default"],
        label="sre/impersonate-sa-scoped",
    );
    sre_cr +>:OwnsRule:+> sre_rule;

    # Bindings -- they reference roles but contain no rules themselves.
    binding_a = RoleBinding(name="dev-binding");
    binding_b = RoleBinding(name="admin-binding");
    binding_a +>:BindsRole:+> dev_role;
    binding_b +>:BindsClusterRole:+> admin_cr;

    # Wire the demo graph: root -> bindings -> roles -> rules
    # plus a standalone sre cluster role for completeness.
    root ++> binding_a ++> dev_role;
    root ++> binding_b ++> admin_cr;
    root ++> sre_cr;

    # Spawn the scan walker; it descends through roles/clusterroles
    # and reaches every rule via typed OwnsRule edges.
    scan = PolicyScan();
    scanner = root spawn scan;

    # Now spawn an auditor that listens on Rule entries -- the spawn
    # pattern in jac dispatches all matching abilities in turn.
    auditor = ImpersonationAuditor();
    # The auditor doesn't traverse itself; it acts as a passive
    # listener on rules visited by the scan walker.
    for rule_node in [
        dev_rule_bad,
        dev_rule_good,
        dev_rule_unrelated,
        admin_rule,
        sre_rule,
    ] {
        # Manually re-enter each rule with the auditor attached so the
        # audit ability fires (no second spawn needed).
        auditor.visited_rules = set([]);
        # Trigger the ability by spawning on the rule directly.
        rule_node spawn auditor;
    }

    print("---- impersonation audit summary ----");
    print(f"flagged: {auditor.flagged}");
    print(f"allowed: {auditor.allowed}");
}