"""Hierarchical queue close/open admission with cascade semantics.

Before-code synthesized from volcano-sh/volcano#5351: the queue controller
cascades Close down to every descendant and rejects Open on a child whose
ancestor is closed, but admission checks none of it. The store keeps
parent pointers plus a children adjacency map; the close cascade is an
explicit stack walk collecting the subtree before flipping states, and the
open check climbs ancestors by hand. Foreground deletion requires the
whole subtree already closed.
"""
"""The request violates hierarchical queue state rules."""
class AdmissionError(ValueError) {}
class QueueTree {
    def init(self: QueueTree)  -> Any {
        self.parent_of = {};
        self.children_of = {};
        self.state_of = {};
    }
    def add_queue(self: QueueTree, name: Any, parent: Any = None)  -> Any {
        if ((parent is not None) and (parent not in self.state_of)) {
            raise KeyError("unknown parent queue");
        }
        self.parent_of[name] = parent;
        if (parent is not None) {
            self.children_of.setdefault(parent, []).append(name);
        }
        self.children_of.setdefault(name, []);
        self.state_of[name] = "Open";
    }
    """Explicit stack walk over the children map; seen-set guarded."""
    def _subtree(self: QueueTree, `root: Any)  -> Any {
        out = [];
        stack = [`root];
        seen = `set();
        while stack {
            cur = stack.pop();
            if (cur in seen) {
                continue;
            }
            seen.add(cur);
            out.append(cur);
            stack.extend(self.children_of.get(cur, []));
        }
        return out;
    }
    def _ancestor_states(self: QueueTree, name: Any)  -> Any {
        chain = [];
        seen = {name};
        cur = self.parent_of.get(name);
        while (cur is not None) {
            if (cur in seen) {
                break;
            }
            seen.add(cur);
            chain.append(self.state_of[cur]);
            cur = self.parent_of.get(cur);
        }
        return chain;
    }
    """Rejected at admission when any ancestor is Closed."""
    def open_queue(self: QueueTree, name: Any)  -> Any {
        if ("Closed" in self._ancestor_states(name)) {
            raise AdmissionError("parent queue is closed");
        }
        self.state_of[name] = "Open";
        return True;
    }
    """Closing a parent synchronously closes ALL descendants."""
    def close_queue(self: QueueTree, name: Any)  -> Any {
        affected = [];
        for q in self._subtree(name) {
            if (self.state_of[q] != "Closed") {
                self.state_of[q] = "Closed";
                affected.append(q);
            }
        }
        return sorted(affected);
    }
    """Foreground deletion waits for a fully-closed subtree.

        Rejects while any descendant is still Open; otherwise removes the
        queue and its whole subtree from the hierarchy.
        """
    def delete_queue_foreground(self: QueueTree, name: Any)  -> Any {
        subtree = self._subtree(name);
        still_open = sorted(
            q
            for q in subtree
            if (self.state_of[q] == "Open")
        );
        if still_open {
            raise AdmissionError(("subtree not closed: %s" % still_open));
        }
        parent = self.parent_of.get(name);
        removed = sorted(list(subtree));
        if (parent is not None) {
            siblings = [
                c
                for c in self.children_of.get(parent, [])
                if (c != name)
            ];
            self.children_of[parent] = siblings;
        }
        for q in subtree {
            self.children_of.pop(q, None);
            self.parent_of.pop(q, None);
            self.state_of.pop(q, None);
        }
        return removed;
    }

    def is_open(self: QueueTree, name: Any)  -> Any {
        return (self.state_of[name] == "Open");
    }
    def descendants(self: QueueTree, name: Any)  -> Any {
        out = [
            q
            for q in self._subtree(name)
            if (q != name)
        ];
        return sorted(out);
    }
}

