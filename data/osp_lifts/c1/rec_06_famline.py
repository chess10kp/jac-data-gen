"""Family lineage records.

Persons link through ``parent`` / ``children`` pointers tracing a
single recorded parental line. Ancestry queries recursively ascend;
blood-relation checks compare ancestor sets; lineage size descends.
"""


class Person:
    def __init__(self, name, birth_year):
        self.name = name
        self.birth_year = birth_year
        self.parent = None       # Person | None (lineage founder)
        self.children = []       # list[Person]


def born(parent, name, birth_year):
    """Record a birth under ``parent`` (None for the founder)."""
    p = Person(name, birth_year)
    if parent is not None:
        p.parent = parent
        parent.children.append(p)
    return p


def ancestor_names(person):
    """Names of direct ancestors, nearest parent first."""
    if person.parent is None:
        return []
    return [person.parent.name] + ancestor_names(person.parent)


def generation_gap(person):
    """Number of generations between ``person`` and the founder."""
    gap = 0
    cur = person.parent
    while cur is not None:
        gap += 1
        cur = cur.parent
    return gap


def is_blood_related(a, b):
    """True when a and b share a lineage: one descends from the other
    or both descend from a common founder/ancestor."""
    kin_a = set([a.name] + ancestor_names(a))
    kin_b = set([b.name] + ancestor_names(b))
    return len(kin_a & kin_b) > 0


def lineage_size(founder):
    """Number of people at or below ``founder``, counting them."""
    return 1 + sum(lineage_size(c) for c in founder.children)


def eldest_line(person):
    """Names on the path from the founder down to ``person``, inclusive."""
    if person.parent is None:
        return [person.name]
    return eldest_line(person.parent) + [person.name]
