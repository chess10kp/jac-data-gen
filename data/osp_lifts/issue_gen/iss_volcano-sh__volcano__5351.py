"""Hierarchical queue close/open admission with cascade semantics.

Before-code synthesized from volcano-sh/volcano#5351: the queue controller
cascades Close down to every descendant and rejects Open on a child whose
ancestor is closed, but admission checks none of it. The store keeps
parent pointers plus a children adjacency map; the close cascade is an
explicit stack walk collecting the subtree before flipping states, and the
open check climbs ancestors by hand. Foreground deletion requires the
whole subtree already closed.
"""


class AdmissionError(ValueError):
    """The request violates hierarchical queue state rules."""


class QueueTree:
    def __init__(self):
        self.parent_of = {}   # name -> parent | None
        self.children_of = {} # name -> [children]
        self.state_of = {}    # name -> "Open" | "Closed"

    def add_queue(self, name, parent=None):
        if parent is not None and parent not in self.state_of:
            raise KeyError("unknown parent queue")
        self.parent_of[name] = parent
        if parent is not None:
            self.children_of.setdefault(parent, []).append(name)
        self.children_of.setdefault(name, [])
        self.state_of[name] = "Open"

    def _subtree(self, root):
        """Explicit stack walk over the children map; seen-set guarded."""
        out = []
        stack = [root]
        seen = set()
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            out.append(cur)
            stack.extend(self.children_of.get(cur, []))
        return out

    def _ancestor_states(self, name):
        chain = []
        seen = {name}
        cur = self.parent_of.get(name)
        while cur is not None:
            if cur in seen:
                break  # tolerate corrupt cycles
            seen.add(cur)
            chain.append(self.state_of[cur])
            cur = self.parent_of.get(cur)
        return chain

    def open_queue(self, name):
        """Rejected at admission when any ancestor is Closed."""
        if "Closed" in self._ancestor_states(name):
            raise AdmissionError("parent queue is closed")
        self.state_of[name] = "Open"
        return True

    def close_queue(self, name):
        """Closing a parent synchronously closes ALL descendants."""
        affected = []
        for q in self._subtree(name):
            if self.state_of[q] != "Closed":
                self.state_of[q] = "Closed"
                affected.append(q)
        return sorted(affected)

    def delete_queue_foreground(self, name):
        """Foreground deletion waits for a fully-closed subtree.

        Rejects while any descendant is still Open; otherwise removes the
        queue and its whole subtree from the hierarchy.
        """
        subtree = self._subtree(name)
        still_open = sorted(q for q in subtree if self.state_of[q] == "Open")
        if still_open:
            raise AdmissionError("subtree not closed: %s" % still_open)
        parent = self.parent_of.get(name)
        removed = sorted(subtree)
        # Apply removals outside collection: detach first, then unregister.
        if parent is not None:
            siblings = [c for c in self.children_of.get(parent, []) if c != name]
            self.children_of[parent] = siblings
        for q in subtree:
            self.children_of.pop(q, None)
            self.parent_of.pop(q, None)
            self.state_of.pop(q, None)
        return removed

    def is_open(self, name):
        return self.state_of[name] == "Open"

    def descendants(self, name):
        out = [q for q in self._subtree(name) if q != name]
        return sorted(out)
