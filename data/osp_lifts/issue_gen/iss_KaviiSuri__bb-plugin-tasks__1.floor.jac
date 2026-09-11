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
with entry {
    TERMINAL = ("done", "canceled");
}
class Board {
    def init(self: Board)  -> Any {
        self.status_of = {};
        self.blockers_of = {};
        self.dependents_of = {};
        self.blocked_cache = {};
    }
    def add_task(self: Board, task_id: Any, status: Any = "todo")  -> Any {
        self.status_of[task_id] = status;
        self.blockers_of.setdefault(task_id, `set());
        self.dependents_of.setdefault(task_id, `set());
        self._refresh_badge(task_id);
    }
    def _is_terminal(self: Board, task_id: Any)  -> Any {
        return (self.status_of[task_id] in TERMINAL);
    }
    """Stack DFS DOWN the dependency graph (dependents_of); guarded."""
    def _reaches(self: Board, src: Any, dst: Any)  -> Any {
        stack = [src];
        seen = `set();
        while stack {
            cur = stack.pop();
            if (cur == dst) {
                return True;
            }
            if (cur in seen) {
                continue;
            }
            seen.add(cur);
            stack.extend(self.dependents_of.get(cur, ()));
        }
        return False;
    }
    """Store edge blocker->dependent; rejects bad links transactionally."""
    def link(self: Board, blocker: Any, dependent: Any)  -> Any {
        if ((blocker not in self.status_of) or (dependent not in self.status_of)) {
            raise KeyError("unknown task");
        }
        if (blocker == dependent) {
            raise ValueError("self link");
        }
        if (blocker in self.blockers_of[dependent]) {
            raise ValueError("duplicate edge");
        }
        if self._reaches(dependent, blocker) {
            raise ValueError("dependency cycle");
        }
        self.blockers_of[dependent].add(blocker);
        self.dependents_of[blocker].add(dependent);
        self._refresh_badge(dependent);
    }
    """Derived, never stored as a workflow status."""
    def _refresh_badge(self: Board, task_id: Any)  -> Any {
        active = [];
        for b in list(self.blockers_of.get(task_id, [])) {
            if not self._is_terminal(b) {
                active.append(b);
            }
        }
        self.blocked_cache[task_id] = (
            not self._is_terminal(task_id) and (len(active) > 0)
        );
        return sorted(active);
    }
    """Invalidation sweep: recompute badges after a status change."""
    def _sweep_dependents(self: Board, task_id: Any)  -> Any {
        touched = {};
        for d in sorted(self.dependents_of[task_id]) {
            touched[d] = self._refresh_badge(d);
        }
        return touched;
    }
    def complete(self: Board, task_id: Any)  -> Any {
        self.status_of[task_id] = "done";
        self._refresh_badge(task_id);
        return self._sweep_dependents(task_id);
    }
    def cancel(self: Board, task_id: Any)  -> Any {
        self.status_of[task_id] = "canceled";
        self._refresh_badge(task_id);
        return self._sweep_dependents(task_id);
    }
    """Reopening recomputes the derived state of dependents."""
    def reopen(self: Board, task_id: Any)  -> Any {
        self.status_of[task_id] = "todo";
        self._refresh_badge(task_id);
        return self._sweep_dependents(task_id);
    }
    def is_blocked(self: Board, task_id: Any)  -> Any {
        return self.blocked_cache.get(task_id, False);
    }
    def unresolved_blocker_count(self: Board, task_id: Any)  -> Any {
        return len(list(self._refresh_badge(task_id)));
    }
    def blocked_tasks(self: Board)  -> Any {
        return sorted(
            t
            for t in self.status_of
            if self.is_blocked(t)
        );
    }
}

