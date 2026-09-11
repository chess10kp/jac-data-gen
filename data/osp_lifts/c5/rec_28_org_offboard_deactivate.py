"""Org directory with cascading offboarding and access revocation.

Employees reference their manager by id; ``reports`` lists direct reports.
Dotted-line management means an employee can appear under two managers,
so the closure walk can reach a person twice -- they must be deactivated
exactly once. Offboarding an employee deactivates everyone in their
reporting closure and revokes each deactivated person's app grants
(a second registry: employee -> set of apps). Unknown ids are a no-op;
re-offboarding reports zero newly deactivated people.
"""


class Employee:
    def __init__(self, emp_id, name):
        self.emp_id = emp_id
        self.name = name
        self.active = True
        self.reports = []       # emp_ids of direct reports
        self.manager_id = None  # primary manager (dotted line possible)
        self.grants = set()     # apps this person may access


class OrgDirectory:
    def __init__(self):
        self.people = {}        # emp_id -> Employee
        self.grant_index = {}   # app -> set of emp_ids (reverse index)

    def hire(self, emp_id, name):
        self.people[emp_id] = Employee(emp_id, name)
        return self.people[emp_id]

    def assign(self, manager_id, report_id):
        if report_id not in self.people or manager_id not in self.people:
            return False        # tolerate unknown refs
        self.people[manager_id].reports.append(report_id)
        self.people[report_id].manager_id = manager_id
        return True

    def grant(self, emp_id, app):
        if emp_id not in self.people:
            return False
        self.people[emp_id].grants.add(app)
        self.grant_index.setdefault(app, set()).add(emp_id)
        return True

    def _collect(self, emp_id, visited, doomed):
        """Recursive descent over reports; once-only per dotted-line reach."""
        if emp_id in visited or emp_id not in self.people:
            return
        visited.add(emp_id)
        person = self.people[emp_id]
        if not person.active:
            return              # already offboarded: stop descending
        doomed.append(person)
        for rid in person.reports:
            self._collect(rid, visited, doomed)

    def offboard(self, emp_id):
        """Deactivate *emp_id* plus the reporting closure.

        Returns (newly_deactivated_sorted, revoked_grant_count). Unknown
        or already-inactive ids report ([], 0).
        """
        if emp_id not in self.people or not self.people[emp_id].active:
            return ([], 0)
        doomed = []
        self._collect(emp_id, set(), doomed)
        revoked = 0
        for person in doomed:
            person.active = False
            for app in person.grants:
                holders = self.grant_index.get(app)
                if holders is not None:
                    holders.discard(person.emp_id)
                revoked += 1
            person.grants.clear()
        return (sorted(p.emp_id for p in doomed), revoked)

    def active_people(self):
        return sorted(e for e, p in self.people.items() if p.active)

    def holders_of(self, app):
        return len(self.grant_index.get(app, ()))


if __name__ == "__main__":
    d = OrgDirectory()
    d.hire("ceo", "Chief")
    d.hire("cta", "Tech")
    d.hire("pm", "Product")
    assert d.assign("ceo", "cta") and d.assign("ceo", "pm")
    assert d.grant("cta", "repo") and d.grant("pm", "design")
    gone, n = d.offboard("ceo")
    print(gone, n, d.active_people(), d.holders_of("repo"))
