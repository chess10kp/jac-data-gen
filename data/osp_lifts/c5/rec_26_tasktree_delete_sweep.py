"""Project task tree with cascade deletion and completed-task preservation.

Tasks reference children by id in ``subtasks``; a task may be listed under
several parents (shared milestone item) and every task records how many
parents hold it in ``holders``. ``delete_task`` removes the requested task,
its exclusive descendants and everything strictly below it -- but a
COMPLETED task roots a preserved island: it is detached, kept alive and
reported back together with its whole subtree. Shared tasks held by another
live parent are likewise spared. A final sweep clears ``parent_id`` back-
references that now dangle. Unknown ids are a silent no-op.
"""


class Task:
    def __init__(self, task_id, title, done=False):
        self.task_id = task_id
        self.title = title
        self.done = done
        self.subtasks = []
        self.parent_id = None
        self.holders = 0


class TaskBoard:
    def __init__(self):
        self.tasks = {}      # task_id -> Task

    def add(self, task_id, title, done=False):
        self.tasks[task_id] = Task(task_id, title, done)
        return self.tasks[task_id]

    def attach(self, parent_id, child_id):
        if child_id not in self.tasks or parent_id not in self.tasks:
            return False     # tolerate unknown refs
        self.tasks[parent_id].subtasks.append(child_id)
        self.tasks[child_id].holders += 1
        self.tasks[child_id].parent_id = parent_id
        return True

    def _collect(self, task_id, doomed, spared):
        """Recursive descent; once-only guard for shared/diamond reaches."""
        if task_id in doomed or task_id in spared:
            return
        if task_id not in self.tasks:
            return           # stale reference tolerated
        task = self.tasks[task_id]
        if task.holders > 1:
            spared.append(task)      # held by another live parent too
            return
        doomed.append(task)
        for child_id in task.subtasks:
            child = self.tasks.get(child_id)
            if child is not None and child.done:
                spared.append(child)          # completed island preserved
                continue
            self._collect(child_id, doomed, spared)

    def delete_task(self, task_id):
        """Delete *task_id* and its open exclusive subtree.

        Completed subtrees and shared tasks survive, detached. Returns the
        sorted ids of preserved tasks; unknown ids report [].
        """
        if task_id not in self.tasks:
            return []
        root = self.tasks[task_id]
        doomed, spared = [], []
        if root.done:
            spared.append(root)      # requesting a done task preserves it
        else:
            doomed.append(root)
            for child_id in root.subtasks:
                child = self.tasks.get(child_id)
                if child is not None and child.done:
                    spared.append(child)
                    continue
                self._collect(child_id, doomed, spared)
        # dying holders release their holds
        for dead in doomed:
            for child_id in dead.subtasks:
                if child_id in self.tasks:
                    self.tasks[child_id].holders -= 1
        for dead in doomed:
            del self.tasks[dead.task_id]
        # sweeper pass: clear dangling parent back-references
        for t in self.tasks.values():
            if t.parent_id is not None and t.parent_id not in self.tasks:
                t.parent_id = None
        return sorted(s.task_id for s in spared)

    def exists(self, task_id):
        return task_id in self.tasks

    def parent_of(self, task_id):
        t = self.tasks.get(task_id)
        return t.parent_id if t else None

    def titles(self):
        return sorted(t.title for t in self.tasks.values())
