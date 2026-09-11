"""Org-chart reporting lines.

Employees form a management tree through ``manager`` / ``reports``
pointers. Reporting queries recursively ascend or descend those
pointers; the CEO is the root employee and has ``manager is None``.
"""


class Employee:
    def __init__(self, name, title):
        self.name = name
        self.title = title
        self.manager = None      # Employee | None
        self.reports = []        # list[Employee], direct reports


def hire(manager, name, title):
    """Add an employee under ``manager`` (None for the CEO); return them."""
    emp = Employee(name, title)
    if manager is not None:
        emp.manager = manager
        manager.reports.append(emp)
    return emp


def management_chain(emp):
    """Titles of managers above ``emp``, nearest manager first."""
    if emp.manager is None:
        return []
    return [emp.manager.title] + management_chain(emp.manager)


def team_size(emp):
    """Headcount of ``emp``'s subtree, including themselves."""
    return 1 + sum(team_size(r) for r in emp.reports)


def org_depth(emp):
    """Length of the longest reporting line below ``emp``, counting them."""
    if not emp.reports:
        return 1
    return 1 + max(org_depth(r) for r in emp.reports)


def find_by_title(root, title):
    """Every employee title match at or below ``root``, sorted."""
    found = []
    if root.title == title:
        found.append(title)
    for r in root.reports:
        found.extend(find_by_title(r, title))
    return sorted(found)
