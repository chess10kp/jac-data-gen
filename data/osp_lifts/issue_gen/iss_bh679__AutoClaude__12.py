"""Task queue with dependency gating and circular-dependency detection.

AutoClaude's daemon keeps an approved task list; tasks may declare that
they depend on other tasks completing first. ``getNextApprovedTask`` must
only return tasks whose dependencies are all completed, ``createTask`` and
``updateTask`` must validate dependency references and reject circular
dependency chains, and the dashboard needs to show both what a task is
waiting for and which tasks depend on a given task.
Ref: bh679/AutoClaude#12
"""


class CircularDependencyError(ValueError):
    """Raised when adding a dependency would create a cycle."""


def new_queue():
    """Fresh task queue handle."""
    return {"tasks": {}}


def add_task(queue, task_id, deps=(), approved=True):
    """Register a task with dependency ids; returns the queue handle.

    Raises KeyError when a dependency references an unknown task and
    CircularDependencyError when the new edges would close a cycle.
    """
    if task_id in queue["tasks"]:
        raise ValueError(f"duplicate task {task_id}")
    for d in deps:
        if d == task_id:
            raise CircularDependencyError(f"task {task_id} cannot depend on itself")
        if d not in queue["tasks"]:
            raise KeyError(f"unknown dependency {d}")
    queue["tasks"][task_id] = {"deps": list(deps), "approved": approved, "completed": False}
    if _would_cycle(queue, task_id):
        del queue["tasks"][task_id]
        raise CircularDependencyError(f"dependency cycle through {task_id}")
    return queue


def update_task(queue, task_id, deps):
    """Replace a task's dependency list; keeps completion/approval state.

    Raises KeyError for unknown task/dependency ids and
    CircularDependencyError when the new edges would close a cycle
    (the original state is preserved on rejection).
    """
    if task_id not in queue["tasks"]:
        raise KeyError(f"unknown task {task_id}")
    for d in deps:
        if d == task_id:
            raise CircularDependencyError(f"task {task_id} cannot depend on itself")
        if d not in queue["tasks"]:
            raise KeyError(f"unknown dependency {d}")
    old = queue["tasks"][task_id]["deps"]
    queue["tasks"][task_id]["deps"] = list(deps)
    if _would_cycle(queue, task_id):
        queue["tasks"][task_id]["deps"] = old
        raise CircularDependencyError(f"dependency cycle through {task_id}")
    return queue


def complete_task(queue, task_id):
    """Mark a task completed; no-op semantics for unknown ids (None out)."""
    task = queue["tasks"].get(task_id)
    if task is None:
        return None
    task["completed"] = True
    return task_id


def get_next_approved(queue):
    """Lowest-id approved, not-completed task whose deps are all completed.

    Returns None when nothing is eligible.
    """
    for tid in sorted(queue["tasks"]):
        t = queue["tasks"][tid]
        if t["approved"] and not t["completed"] and all(
            queue["tasks"][d]["completed"] for d in t["deps"]
        ):
            return tid
    return None


def waiting_for(queue, task_id):
    """Sorted dependency ids of ``task_id`` that are not yet completed."""
    t = queue["tasks"].get(task_id)
    if t is None:
        return []
    return sorted(d for d in t["deps"] if not queue["tasks"][d]["completed"])


def dependents(queue, task_id):
    """Sorted ids of tasks that (transitively) depend on ``task_id``."""
    result = set()

    def visit(tid):
        for other, t in queue["tasks"].items():
            if tid in t["deps"] and other not in result:
                result.add(other)
                visit(other)

    visit(task_id)
    return sorted(result)


def _would_cycle(queue, task_id):
    """True when following deps from ``task_id`` loops back to it."""
    seen = set()
    stack = list(queue["tasks"][task_id]["deps"])
    while stack:
        cur = stack.pop()
        if cur == task_id:
            return True
        if cur in seen:
            continue
        seen.add(cur)
        stack.extend(queue["tasks"][cur]["deps"])
    return False
