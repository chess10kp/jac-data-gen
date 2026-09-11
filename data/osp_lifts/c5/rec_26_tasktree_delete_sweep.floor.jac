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
class Task {
    has task_id: str;
    has title: str;
    has done: bool = False;
    has parent_id: str | None = None;
    has holders: int = 0;
    def init(self: Task, task_id: str, title: str, done: bool = False) -> object {
        self.task_id = task_id;
        self.title = title;
        self.done = done;
        self.subtasks = [];
        self.parent_id = None;
        self.holders = 0;
    }
}
class TaskBoard {
    has tasks: dict[str, Task];
    def init(self: TaskBoard) -> object {
        self.tasks = {};
    }
    def add(self: TaskBoard, task_id: str, title: str, done: bool = False) -> object {
        self.tasks[task_id] = Task(task_id, title, done);
        return self.tasks[task_id];
    }
    def attach(self: TaskBoard, parent_id: str, child_id: str) -> object {
        if ((child_id not in self.tasks) or (parent_id not in self.tasks)) {
            return False;
        }
        self.tasks[parent_id].subtasks.append(child_id);
        self.tasks[child_id].holders += 1;
        self.tasks[child_id].parent_id = parent_id;
        return True;
    }
    def _collect(self: TaskBoard, task_id: str, doomed: list[Task], spared: list[Task]) -> object {
        if ((task_id in doomed) or (task_id in spared)) {
            return;
        }
        if (task_id not in self.tasks) {
            return;
        }
        task = self.tasks[task_id];
        if (task.holders > 1) {
            spared.append(task);
            return;
        }
        doomed.append(task);
        for child_id in task.subtasks {
            child = self.tasks.get(child_id);
            if ((child is not None) and child.done) {
                spared.append(child);
                continue;
            }
            self._collect(child_id, doomed, spared);
        }
    }
    def delete_task(self: TaskBoard, task_id: str) -> object {
        if (task_id not in self.tasks) {
            return [];
        }
        `root = self.tasks[task_id];
        (doomed, spared) = ([], []);
        if `root.done {
            spared.append(`root);
        } else {
            doomed.append(`root);
            for child_id in `root.subtasks {
                child = self.tasks.get(child_id);
                if ((child is not None) and child.done) {
                    spared.append(child);
                    continue;
                }
                self._collect(child_id, doomed, spared);
            }
        }
        for dead in doomed {
            for child_id in dead.subtasks {
                if (child_id in self.tasks) {
                    self.tasks[child_id].holders -= 1;
                }
            }
        }
        for dead in doomed {
            delete(self.tasks[dead.task_id],);
        }
        for t in self.tasks.values() {
            if ((t.parent_id is not None) and (t.parent_id not in self.tasks)) {
                t.parent_id = None;
            }
        }
        return sorted(s.task_id for s in spared);
    }

    def exists(self: TaskBoard, task_id: str) -> object {
        return (task_id in self.tasks);
    }
    def parent_of(self: TaskBoard, task_id: str) -> object {
        t = self.tasks.get(task_id);
        return t.parent_id if t else None;
    }
    def titles(self: TaskBoard) -> object {
        return sorted(t.title for t in self.tasks.values());
    }
}

