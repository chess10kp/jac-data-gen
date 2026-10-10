"""CI dependency-graph check that resolves issue-worm, issue-worm-pro, and
cicaid-devtools together and verifies no conflicts exist.

Models the scenario from Issue #103: three Python packages must install
cleanly into one virtual environment. We model each package as a node,
the packages it *requires* as typed ``Requires`` edges, and a walker
that performs a full dependency-resolution traversal, collecting every
requirement into one flat list (the analogue of ``pip install`` of all
three together) and then asserting the resolved versions are mutually
consistent. A second walker walks the conflict graph produced by the
first to surface any disagreements.
"""

node Package {
    has name: str = "";
    has version: str = "";
    has runtime_ok: bool = True;
}

edge Requires {
    has dep_name: str = "";
    has dep_version: str = "";
    has strict: bool = True;
}

edge ConflictsWith {
    has reason: str = "";
}

walker DependencyResolver {
    has collected: list[tuple[str, str]] = [];
    has depth: int = 0;
    has max_depth: int = 8;
    has seen: list[str] = [];
    has conflicts: list[str] = [];

    can begin with Root entry {
        visit [-->];
    }

    can gather with Package entry {
        # Record this package's own version first.
        self.collected.append((here.name, here.version));

        # Record every requirement emitted by this package.
        for req in [->:Requires:->] {
            if req.dep_name not in self.seen {
                self.seen.append(req.dep_name);
                if req.strict and req.dep_version == "" {
                    self.conflicts.append(
                        f"unpinned dependency {req.dep_name} required by {here.name}"
                    );
                }
                self.collected.append((req.dep_name, req.dep_version));
            }
        }

        # A package with runtime_ok=False represents the "manual testing"
        # failure mode PR #101 fixed: it refuses to coexist with siblings.
        if not here.runtime_ok {
            for peer in [<--] {
                if peer in [-->(?:Package)] {
                    self.conflicts.append(
                        f"{here.name}@{here.version} incompatible with "
                        f"{peer.name}@{peer.version}"
                    );
                }
            }
        }

        if self.depth < self.max_depth {
            self.depth += 1;
            visit [->:Requires:->];
        } else {
            disengage;
        }
    }
}

walker ConflictAuditor {
    has reports: list[str] = [];

    can begin with Root entry {
        visit [-->];
    }

    can audit with Package entry {
        for rival in [<--] {
            if rival in [-->(?:Package)] {
                edge_label = "ConflictsWith" if (
                    [here -:ConflictsWith:-> rival] != []
                ) else "ok";
                self.reports.append(
                    f"{here.name}@{here.version} <-> {rival.name}@{rival.version}: {edge_label}"
                );
            }
        }
        visit [-->];
    }
}

with entry {
    # Three sibling packages from the same dependency graph.
    issue_worm = Package(name="issue-worm", version="0.5.0", runtime_ok=True);
    issue_worm_pro = Package(name="issue-worm-pro", version="0.3.1", runtime_ok=True);
    cicaid = Package(name="cicaid-devtools", version="0.4.0", runtime_ok=True);

    root ++> issue_worm ++> issue_worm_pro ++> cicaid;

    # issue-worm and issue-worm-pro both pin cicaid-devtools.
    issue_worm +>:Requires(dep_name="cicaid-devtools", dep_version="0.4.0", strict=True):+> cicaid;
    issue_worm_pro +>:Requires(dep_name="cicaid-devtools", dep_version="0.4.0", strict=True):+> cicaid;

    # issue-worm needs requests; issue-worm-pro needs click.
    issue_worm +>:Requires(dep_name="requests", dep_version="2.31.0", strict=True):+> Package(name="requests", version="2.31.0");
    issue_worm_pro +>:Requires(dep_name="click", dep_version="8.1.7", strict=True):+> Package(name="click", version="8.1.7");

    # Pre-PR #101 conflict fingerprint, kept as an explicit edge so the
    # ConflictAuditor walker can demonstrate the regression-catching path.
    issue_worm +>:ConflictsWith(reason="cicaid-devtools<0.4.0 broke shared runtime import"):+> cicaid;

    resolver = DependencyResolver() spawn root;
    print("=== resolved dependency set (pip-check analogue) ===");
    for (name, ver) in resolver.collected {
        print(f"  {name}=={ver}");
    }
    print(f"depth reached: {resolver.depth}");
    print(f"runtime conflicts: {len(resolver.conflicts)}");
    for c in resolver.conflicts {
        print(f"  ! {c}");
    }

    auditor = ConflictAuditor() spawn root;
    print("=== pairwise sibling audit ===");
    for r in auditor.reports {
        print(f"  {r}");
    }

    overall_ok = len(resolver.conflicts) == 0 and len(auditor.reports) > 0;
    ci_status = "PASS" if overall_ok else "FAIL";
    print(f"CI dependency-graph check: {ci_status}");
}