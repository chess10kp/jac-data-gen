"""Zone capacity tree: hierarchy of work areas with rolled-up effort counts.

Before-code synthesized from kitelev/exocortex#4196: capacity reporting walks
the zone hierarchy (TBank -> Sales Offering -> TOOS Group -> ...). The issue
ships the hand-rolled pattern verbatim: a ``children_map`` built from parent
pointers, a recursive ``aggregate_capacity`` that sums every subtree, an
``ancestors`` chain walk, and depth-filtered descendant queries. Cyclic
references (A -> B -> A) must terminate without duplicates instead of
crashing the script. Parent pointers, adjacency lists, and recursion below.
"""


class ZoneTree:
    def __init__(self):
        self.parent_of = {}    # zone -> parent | None
        self.children = {}     # zone -> list of direct child zones
        self.efforts = {}      # zone -> directly assigned effort count

    def add_zone(self, name, parent=None):
        if parent is not None and parent not in self.parent_of:
            raise KeyError("unknown parent zone")
        self.parent_of[name] = parent
        self.children.setdefault(name, [])
        self.efforts.setdefault(name, 0)
        if parent is not None:
            self.children[parent].append(name)

    def assign(self, zone, n=1):
        if zone not in self.parent_of:
            raise KeyError("unknown zone")
        self.efforts[zone] += n

    def direct_capacity(self, zone):
        if zone not in self.parent_of:
            raise KeyError("unknown zone")
        return self.efforts[zone]

    def aggregate(self, zone):
        """Subtree sum: own efforts plus everything beneath (cycle-tolerant)."""
        if zone not in self.parent_of:
            raise KeyError("unknown zone")
        total = 0
        seen = set()
        stack = [zone]
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            total += self.efforts[cur]
            stack.extend(self.children[cur])
        return total

    def ancestors(self, zone):
        """Chain of parents above ``zone`` (nearest first), tolerating corrupt cycles."""
        if zone not in self.parent_of:
            raise KeyError("unknown zone")
        chain = []
        seen = {zone}
        cur = self.parent_of[zone]
        while cur is not None:
            if cur in seen:
                break
            seen.add(cur)
            chain.append(cur)
            cur = self.parent_of[cur]
        return chain

    def descendants(self, zone, depth=None):
        """All zones beneath ``zone``; only those at exactly ``depth`` levels
        below when depth is given. Sorted, duplicate-free, cycle-tolerant."""
        if zone not in self.parent_of:
            raise KeyError("unknown zone")
        depths = {zone: 0}
        queue = [zone]
        i = 0
        while i < len(queue):
            cur = queue[i]
            i += 1
            for ch in self.children[cur]:
                if ch not in depths:
                    depths[ch] = depths[cur] + 1
                    queue.append(ch)
        out = []
        for name, d in depths.items():
            if d > 0 and (depth is None or d == depth):
                out.append(name)
        return sorted(out)
