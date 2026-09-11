"""Idiomatic OSP lift: org offboarding cascade with grant revocation
(category C5, two-phase §5.5).

Phase COLLECT -- `OffboardScan` walks `Manages` edges gathering the
deactivation closure into typed `has` fields. The seen-guard handles
dotted-line diamonds (a person reached via two managers is collected
once) and doubles as the explicit cycle policy -- 0.36.1 has no built-in
dedup; `skip;` keeps sibling branches alive. Already-inactive people stop
their branch.

Phase APPLY -- outside any walk: flags flip, `Revokes` edges and grants
are cleared, and the reverse grant index is updated. Kept semantics:
unknown or already-inactive ids are a no-op returning ([], 0).
"""

node Employee {
    has emp_id: str;
    has name: str;
    has active: bool = True;
    has apps: list[str] = [];       # granted apps (payload kept on node)
}

edge Manages { }

"""Collect the reporting closure below one employee."""
walker OffboardScan {
    has doomed: list[Employee] = [];
    has seen: dict[str, bool] = {};

    can scan with Employee entry {
        if here.emp_id in self.seen {
            skip;           # dotted-line revisit / cycle policy: once only,
        }                   # keep sibling branches alive (no disengage)
        self.seen[here.emp_id] = True;
        if not here.active {
            skip;           # already offboarded: stop this branch
        }
        self.doomed.append(here);
        visit [->:Manages:->];
    }
}

obj OrgDirectory {
    has people: dict[str, Employee];
    has grant_index: dict[str, list[str]];   # app -> emp_ids (reverse idx)

    def hire(emp_id: str, name: str) -> Employee {
        fresh = Employee(emp_id=emp_id, name=name);
        self.people[emp_id] = fresh;
        return fresh;
    }

    def assign(manager_id: str, report_id: str) -> bool {
        mgr = self.people.get(manager_id);
        rep = self.people.get(report_id);
        if rep is None or mgr is None {
            return False;                   # tolerate unknown refs
        }
        mgr +>:Manages:+> rep;
        return True;
    }

    def grant(emp_id: str, app: str) -> bool {
        person = self.people.get(emp_id);
        if person is None {
            return False;
        }
        person.apps.append(app);
        holders = self.grant_index.get(app);
        if holders is None {
            self.grant_index[app] = [emp_id];
        } else {
            holders.append(emp_id);
        }
        return True;
    }

    """Deactivate *emp_id* plus its closure; revokes all their grants.

    Returns (newly deactivated sorted, revoked grant count).
    """
    def offboard(emp_id: str) -> tuple[list[str], int] {
        start = self.people.get(emp_id);
        if start is None or not start.active {
            return ([], 0);
        }
        # Phase COLLECT -- walk once, mutate never.
        scan = start spawn OffboardScan();
        doomed = scan.doomed;

        # Phase APPLY -- strictly after the walk finished.
        revoked = 0;
        for person in doomed {
            person.active = False;
            held = len(person.apps);
            for app in person.apps as list[str] {
                holders = self.grant_index.get(app);
                if holders is not None {
                    keep = [e for e in holders if e != person.emp_id];
                    self.grant_index[app] = keep;
                }
            }
            revoked += held;
            person.apps = [];
        }
        return (sorted(p.emp_id for p in doomed), revoked);
    }

    def active_people -> list[str] {
        live = [e for e in self.people.keys() if self.people[e].active];
        return sorted(live);
    }

    def holders_of(app: str) -> int {
        holders = self.grant_index.get(app);
        if holders is None {
            return 0;
        }
        return len(holders);
    }
}

"""Build a fresh deterministic directory; creation order = fixture order."""
def load_graph(spec: list[tuple[str, str]],
               links: list[tuple[str, str]],
               grants: list[tuple[str, str]]) -> OrgDirectory {
    d = OrgDirectory(people={}, grant_index={});
    for row in spec {
        _made = d.hire(row[0], row[1]);
    }
    for pair in links {
        _ok = d.assign(pair[0], pair[1]);
    }
    for pair in grants {
        _g = d.grant(pair[0], pair[1]);
    }
    return d;
}
