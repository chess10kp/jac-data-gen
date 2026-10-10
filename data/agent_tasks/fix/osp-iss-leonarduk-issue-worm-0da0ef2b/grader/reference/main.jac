"""Dependency graph validator: model the three packages as nodes and verify
their mutual compatibility by walking a typed dependency graph.

Reproduces the hand-rolled machinery from the issue's mental model:
    - each package is a node
    - its declared dependencies are typed edges to other package/version nodes
    - a walker does a BFS over the dependency edges, accumulates a flat
      resolution, and then checks for duplicate packages with conflicting
      version constraints -- exactly the conflict class `pip check` would
      raise for issue-worm + cicaid-devtools before PR #101.
"""

# ----- node archetypes ---------------------------------------------------------

node Package {
    has name: str = "";
    has version: str = "";
}

# A concrete pin a package declares (e.g. "cicaid-devtools==0.2.4").
node VersionPin {
    has raw_constraint: str = "";
}

# ----- edge archetypes ---------------------------------------------------------

# "This package declares this version pin as a dependency."
edge Requires {
    has kind: str = "runtime";
}

# "This pin points to a specific package+version."
edge ResolvesTo {
    # empty payload -- the target Package node carries name+version
}

# ----- walker ------------------------------------------------------------------

walker Resolver {
    has visited: list[str] = [];
    has resolutions: dict[str, str] = {};
    has conflicts: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    # Entering a Package: record/verify its version.
    can visit_pkg with Package entry {
        key = here.name;
        already = key in self.resolutions;
        if already {
            existing = self.resolutions[key];
            if existing != here.version {
                msg = f"CONFLICT: {key} required as {existing} and {here.version}";
                self.conflicts.append(msg);
            }
        } else {
            self.resolutions[key] = here.version;
        }
        # Walk into the version pins this package declares.
        visit [->:Requires:->];
    }

    # A declared pin (e.g. "cicaid-devtools==0.2.4") -- parse and follow.
    can visit_pin with VersionPin entry {
        raw = here.raw_constraint;
        # Tolerate both "==" and ">=" styles for the demo.
        sep_pos = raw.find("==");
        op = "==";
        rhs_start = sep_pos + 2;
        if sep_pos < 0 {
            sep_pos = raw.find(">=");
            op = ">=";
            rhs_start = sep_pos + 2;
        }
        if sep_pos < 0 {
            self.conflicts.append(f"UNPARSED PIN: {raw}");
            return;
        }
        name = raw[:sep_pos];
        version = raw[rhs_start:];
        # Record the pin as a transitive resolution target.
        pin_key = name;
        already = pin_key in self.resolutions;
        if already {
            existing = self.resolutions[pin_key];
            if existing != version {
                msg = f"CONFLICT: {pin_key} required as {existing} and {version} ({op})";
                self.conflicts.append(msg);
            }
        } else {
            self.resolutions[pin_key] = version;
        }
        visit [->:ResolvesTo:->];
    }

    # A Package node reached via ResolvesTo: visit it through the pkg ability.
    can reach_pkg with Package entry {
        # Same logic as visit_pkg, factored through here for clarity.
        key = here.name;
        already = key in self.resolutions;
        if already {
            existing = self.resolutions[key];
            if existing != here.version {
                msg = f"CONFLICT: {key} required as {existing} and {here.version}";
                self.conflicts.append(msg);
            }
        } else {
            self.resolutions[key] = here.version;
        }
        visit [-->];
    }
}

# ----- demo wiring -------------------------------------------------------------

with entry {
    # The three packages at their pre-PR-#101 versions.
    issue_worm      = Package(name="issue-worm",       version="0.3.1");
    issue_worm_pro  = Package(name="issue-worm-pro",   version="0.1.0");
    cicaid_old      = Package(name="cicaid-devtools",  version="0.2.4");

    # And the post-fix version that PR #101 promoted to.
    cicaid_new      = Package(name="cicaid-devtools",  version="0.4.0");

    # Pins issue-worm and issue-worm-pro declare.
    pin_iw_cicaid   = VersionPin(raw_constraint="cicaid-devtools==0.2.4");
    pin_iwpro_cicaid = VersionPin(raw_constraint="cicaid-devtools==0.2.4");

    # Pre-fix graph: both packages pin cicaid-devtools to the *same* old version
    # (no conflict), but a third actor is about to demand 0.4.0 -- that
    # mirrors the situation PR #101 detected.
    root ++> issue_worm +>:Requires:+> pin_iw_cicaid +>:ResolvesTo:+> cicaid_old;
    root ++> issue_worm_pro +>:Requires:+> pin_iwpro_cicaid +>:ResolvesTo:+> cicaid_old;

    # A *newer* requirement (e.g. a downstream consumer or pro upgrade) wants
    # 0.4.0. This is the conflict the CI job must catch.
    pro_upgrade     = VersionPin(raw_constraint="cicaid-devtools==0.4.0");
    root ++> pro_upgrade +>:ResolvesTo:+> cicaid_new;

    # First walk: pre-fix expectation -- should be clean.
    pre = Resolver();
    root spawn pre;
    print(f"PRE-FIX  conflicts={len(pre.conflicts)} resolutions={pre.resolutions}");

    # Now flip a pin to the new version to simulate the post-PR state and
    # show the conflict emerging.
    pin_iwpro_cicaid.raw_constraint = "cicaid-devtools==0.4.0";

    post = Resolver();
    root spawn post;
    print(f"POST-FIX conflicts={len(post.conflicts)} resolutions={post.resolutions}");
    for c in post.conflicts {
        print(f"  {c}");
    }
}
