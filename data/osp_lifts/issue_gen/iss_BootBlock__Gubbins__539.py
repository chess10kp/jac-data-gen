"""Kit containment graph: validated links and guarded component reads.

BootBlock/Gubbins#539: addKitComponent enforces acyclicity with a
recursive descendant walk before it writes, and the reader that expands a
kit's transitive components recurses without a cycle guard -- a merged
graph holding X contains Y contains X overflows the stack. The in-memory
core below keeps the containment edge table, the pre-write validation walk,
and the transitive component expansion; the hardened contract raises a
controlled ContainmentCycleError on an existing loop instead of crashing.
"""


class ContainmentCycleError(ValueError):
    """A kit containment loop exists or would be created."""


class KitStore:
    def __init__(self):
        self.is_kit = {}    # item id -> bool
        self.contains = []  # (kit_item_id, component_item_id)

    def add_item(self, iid, is_kit=False):
        self.is_kit[iid] = bool(is_kit)

    def _require(self, *iids):
        for i in iids:
            if i not in self.is_kit:
                raise KeyError(i)

    def direct_components(self, kit):
        return sorted(c for k, c in self.contains if k == kit)  # table rescan

    def add_kit_component(self, kit, component):
        """Link component into kit unless that closes a containment loop."""
        self._require(kit, component)
        if not self.is_kit[kit]:
            raise ValueError("not a kit")
        if kit == component:
            raise ContainmentCycleError("self-containment")
        seen = {component}
        stack = [component]
        while stack:  # pre-write validation: does component contain kit?
            cur = stack.pop()
            if cur == kit:
                raise ContainmentCycleError("kit inside its own component")
            for nxt in self.direct_components(cur):
                if nxt not in seen:
                    seen.add(nxt)
                    stack.append(nxt)
        self.contains.append((kit, component))

    def all_components(self, kit):
        """Transitive components of kit; revisits skipped, always finite."""
        seen = set()
        stack = [kit]
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue  # diamond/cycle revisit: skip silently
            seen.add(cur)
            stack.extend(self.direct_components(cur))
        return sorted(seen - {kit})

    def has_containment_cycle(self, kit):
        """True when any root-to-node path from kit closes a loop."""
        stack = [(kit, frozenset())]
        while stack:
            cur, path = stack.pop()
            if cur in path:
                return True
            for c in reversed(self.direct_components(cur)):
                stack.append((c, path | {cur}))
        return False

    def kit_count(self):
        return sum(1 for v in self.is_kit.values() if v)
