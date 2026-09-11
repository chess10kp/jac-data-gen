"""Org directory with cascading offboarding and access revocation.

Employees reference their manager by id; ``reports`` lists direct reports.
Dotted-line management means an employee can appear under two managers,
so the closure walk can reach a person twice -- they must be deactivated
exactly once. Offboarding an employee deactivates everyone in their
reporting closure and revokes each deactivated person's app grants
(a second registry: employee -> set of apps). Unknown ids are a no-op;
re-offboarding reports zero newly deactivated people.
"""
class Employee {
    has emp_id: str;
    has name: str;
    has active: bool = True;
    has grants: set[str] = set();
    has reports: list[str] = [];
    has manager_id: str | None = None;
    def init(self: Employee, emp_id: str, name: str) -> object {
        self.emp_id = emp_id;
        self.name = name;
        self.active = True;
        self.reports = [];
        self.manager_id = None;
        self.grants = set();
    }
}
class OrgDirectory {
    has people: dict[str, Employee];
    has grant_index: dict[str, set[str]];
    def init(self: OrgDirectory) -> object {
        self.people = {};
        self.grant_index = {};
    }
    def hire(self: OrgDirectory, emp_id: str, name: str) -> object {
        self.people[emp_id] = Employee(emp_id, name);
        return self.people[emp_id];
    }
    def assign(self: OrgDirectory, manager_id: str, report_id: str) -> object {
        if ((report_id not in self.people) or (manager_id not in self.people)) {
            return False;
        }
        self.people[manager_id].reports.append(report_id);
        self.people[report_id].manager_id = manager_id;
        return True;
    }
    def grant(self: OrgDirectory, emp_id: str, app: str) -> object {
        if (emp_id not in self.people) {
            return False;
        }
        self.people[emp_id].grants.add(app);
        self.grant_index.setdefault(app, set()).add(emp_id);
        return True;
    }
    def _collect(self: OrgDirectory, emp_id: str, visited: set[str], doomed: list[Employee]) -> object {
        if ((emp_id in visited) or (emp_id not in self.people)) {
            return;
        }
        visited.add(emp_id);
        person = self.people[emp_id];
        if not person.active {
            return;
        }
        doomed.append(person);
        for rid in person.reports {
            self._collect(rid, visited, doomed);
        }
    }
    def offboard(self: OrgDirectory, emp_id: str) -> tuple[list[str], int] {
        if ((emp_id not in self.people) or not self.people[emp_id].active) {
            return ([], 0);
        }
        doomed: list[Employee] = [];
        self._collect(emp_id, set(), doomed);
        revoked = 0;
        for person in doomed {
            person.active = False;
            apps = person.grants as set[str];
            for app in apps {
                holders = self.grant_index.get(app);
                holder_ids = holders as set[str];
                if (holders is not None) {
                    holder_ids.discard(person.emp_id);
                }
                revoked += 1;
            }
            person.grants.clear();
        }
        return (sorted(p.emp_id for p in doomed), revoked);
    }

    def active_people(self: OrgDirectory) -> object {
        return sorted(
            e
            for (e, p) in self.people.items()
            if p.active
        );
    }
    def holders_of(self: OrgDirectory, app: str) -> object {
        return len(self.grant_index.get(app, ()));
    }
}

with entry {
    if (__name__ == "__main__") {
        d = OrgDirectory();
        d.hire("ceo", "Chief");
        d.hire("cta", "Tech");
        d.hire("pm", "Product");
        assert (d.assign("ceo", "cta") and d.assign("ceo", "pm"));
        assert (d.grant("cta", "repo") and d.grant("pm", "design"));
        (gone, n) = d.offboard("ceo");
        print(gone, n, d.active_people(), d.holders_of("repo"));
    }
}

