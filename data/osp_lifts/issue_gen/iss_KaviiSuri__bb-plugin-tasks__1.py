"""Task dependencies and derived blocking.

Before-code synthesized from KaviiSuri/bb-plugin-tasks#1: Linear-style
directed task edges where ``B blocks A`` is one stored edge with two views.
Blocked is DERIVED, never a stored workflow status: completing or canceling
a blocker unblocks dependents, reopening may re-block them. Counts are
direct-only (chains are not flattened), parent/subtask nesting does not
propagate blocking, and linking must transactionally reject self-links,
duplicates, and cycles -- including cycles that pass through already
resolved edges. The board keeps forward and reverse adjacency dicts;
cycle checks are explicit stack DFS with a visited set.
"""

TERMINAL = ("done", "canceled")


class Board:
    def __init__(self):
        self.status_of = {}     # task_id -> status
        self.blockers_of = {}   # task -> set of direct blocker ids (B -> A)
        self.dependents_of = {} # task -> set of direct dependent ids
        self.blocked_cache = {} # derived badge per task

    def add_task(self, task_id, status="todo"):
        self.status_of[task_id] = status
        self.blockers_of.setdefault(task_id, set())
        self.dependents_of.setdefault(task_id, set())
        self._refresh_badge(task_id)

    def _is_terminal(self, task_id):
        return self.status_of[task_id] in TERMINAL

    def _reaches(self, src, dst):
        """Stack DFS DOWN the dependency graph (dependents_of); guarded."""
        stack = [src]
        seen = set()
        while stack:
            cur = stack.pop()
            if cur == dst:
                return True
            if cur in seen:
                continue
            seen.add(cur)
            stack.extend(self.dependents_of.get(cur, ()))
        return False

    def link(self, blocker, dependent):
        """Store edge blocker->dependent; rejects bad links transactionally."""
        if blocker not in self.status_of or dependent not in self.status_of:
            raise KeyError("unknown task")
        if blocker == dependent:
            raise ValueError("self link")
        if blocker in self.blockers_of[dependent]:
            raise ValueError("duplicate edge")
        # Cycle check includes preserved resolved edges by design.
        if self._reaches(dependent, blocker):
            raise ValueError("dependency cycle")
        self.blockers_of[dependent].add(blocker)
        self.dependents_of[blocker].add(dependent)
        self._refresh_badge(dependent)

    def _refresh_badge(self, task_id):
        """Derived, never stored as a workflow status."""
        active = []
        for b in self.blockers_of[task_id]:
            if not self._is_terminal(b):
                active.append(b)
        self.blocked_cache[task_id] = (
            not self._is_terminal(task_id) and len(active) > 0
        )
        return sorted(active)

    def _sweep_dependents(self, task_id):
        """Invalidation sweep: recompute badges after a status change."""
        touched = {}
        for d in sorted(self.dependents_of[task_id]):
            touched[d] = self._refresh_badge(d)
        return touched

    def complete(self, task_id):
        self.status_of[task_id] = "done"
        self._refresh_badge(task_id)
        return self._sweep_dependents(task_id)

    def cancel(self, task_id):
        self.status_of[task_id] = "canceled"
        self._refresh_badge(task_id)
        return self._sweep_dependents(task_id)

    def reopen(self, task_id):
        """Reopening recomputes the derived state of dependents."""
        self.status_of[task_id] = "todo"
        self._refresh_badge(task_id)
        return self._sweep_dependents(task_id)

    def is_blocked(self, task_id):
        return self.blocked_cache.get(task_id, False)

    def unresolved_blocker_count(self, task_id):
        return len(self._refresh_badge(task_id))

    def blocked_tasks(self):
        return sorted(t for t in self.status_of if self.is_blocked(t))
