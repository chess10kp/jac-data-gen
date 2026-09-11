"""DNS wire hierarchy.

Domains nest through ``parent`` / ``subs`` pointers from the root
zone downward. FQDN construction and zone chains ascend; delegated
subdomain counts descend. Zone boundaries are payload flags that the
chain query must respect.
"""


class Domain:
    def __init__(self, label, is_zone=False):
        self.label = label
        self.is_zone = is_zone   # True where delegation starts
        self.parent = None       # Domain | None (root zone)
        self.subs = []           # list[Domain], delegated subdomains


def register(parent, label, is_zone=False):
    """Delegate ``label`` under ``parent`` (None for the root zone)."""
    d = Domain(label, is_zone)
    if parent is not None:
        d.parent = parent
        parent.subs.append(d)
    return d


def fqdn(d):
    """Fully qualified name of ``d``, built by ascending to the root."""
    if d.parent is None:
        return d.label + "."
    return fqdn(d.parent) + d.label + "."


def zone_chain(d):
    """Zone names on the path to the root, nearest zone first.

    Only labels where ``is_zone`` is True participate; ``d``'s own label
    counts when it hosts a zone.
    """
    chain = []
    cur = d
    while cur is not None:
        if cur.is_zone:
            chain.append(cur.label)
        cur = cur.parent
    return chain


def subdomain_count(zone):
    """Delegated domains strictly below ``zone``."""
    total = 0
    for s in zone.subs:
        total += 1 + subdomain_count(s)
    return total


def soa_distance(d):
    """Hops from ``d`` up to the nearest enclosing zone host (itself counts)."""
    hops = 1
    cur = d
    while not cur.is_zone:
        cur = cur.parent
        if cur is None:
            break
        hops += 1
    return hops if cur is not None and cur.is_zone else -1
