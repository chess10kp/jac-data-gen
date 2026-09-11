"""Kit containment graph: validated links and guarded component reads.

BootBlock/Gubbins#539: addKitComponent enforces acyclicity with a
recursive descendant walk before it writes, and the reader that expands a
kit's transitive components recurses without a cycle guard -- a merged
graph holding X contains Y contains X overflows the stack. The in-memory
core below keeps the containment edge table, the pre-write validation walk,
and the transitive component expansion; the hardened contract raises a
controlled ContainmentCycleError on an existing loop instead of crashing.
"""
"""A kit containment loop exists or would be created."""
class ContainmentCycleError(ValueError) {}
class KitStore {
    def init(self: KitStore) -> object {
        self.is_kit = {};
        self.contains = [];
    }
    def add_item(self: KitStore, iid: Any, is_kit: Any = False) -> object {
        self.is_kit[iid] = bool(is_kit);
    }
    def _require(self: KitStore, *iids: Any) -> object {
        for i in iids {
            if (i not in self.is_kit) {
                raise KeyError(i);
            }
        }
    }
    def direct_components(self: KitStore, kit: Any) -> list {
        return sorted(
            c
            for (k, c) in self.contains
            if (k == kit)
        );
    }
    """Link component into kit unless that closes a containment loop."""
    def add_kit_component(self: KitStore, kit: Any, component: Any) -> object {
        self._require(kit, component);
        if not self.is_kit[kit] {
            raise ValueError("not a kit");
        }
        if (kit == component) {
            raise ContainmentCycleError("self-containment");
        }
        seen = {component};
        stack = [component];
        while stack {
            cur = stack.pop();
            if (cur == kit) {
                raise ContainmentCycleError("kit inside its own component");
            }
            for nxt in self.direct_components(cur) {
                if (nxt not in seen) {
                    seen.add(nxt);
                    stack.append(nxt);
                }
            }
        }
        self.contains.append((kit, component));
    }
    """Transitive components of kit; revisits skipped, always finite."""
    def all_components(self: KitStore, kit: Any) -> list {
        seen = `set();
        stack = [kit];
        while stack {
            cur = stack.pop();
            if (cur in seen) {
                continue;
            }
            seen.add(cur);
            stack.extend(self.direct_components(cur));
        }
        return sorted((seen - {kit}));
    }
    """True when any root-to-node path from kit closes a loop."""
    def has_containment_cycle(self: KitStore, kit: Any) -> object {
        stack = [(kit, frozenset())];
        while stack {
            (cur, path) = stack.pop();
            if (cur in path) {
                return True;
            }
            for c in reversed(self.direct_components(cur)) {
                stack.append((c, (path | {cur})));
            }
        }
        return False;
    }
    def kit_count(self: KitStore) -> object {
        return sum(
            1
            for v in self.is_kit.values()
            if v
        );
    }
}

