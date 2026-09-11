"""Guard for rec_26_tasktree_delete_sweep -- candidate OSP lift inlined
verbatim (same-prefix sibling imports are unreliable across jac's native
seam), plus behavioral tests: open-branch deletion with done-island
preservation, shared task spared then deleted with its last holder,
done-root no-op requests, dangling back-reference sweep, unknown ids.
"""


node Task {
    has task_id: str;
    has title: str;
    has done: bool = False;
    has parent_id: str | None = None;
    has holders: int = 0;
}

edge Tracks { }

"""Split one subtree into doomed and preserved tasks."""
walker DeleteScan {
    has doomed: list[Task] = [];
    has preserved: list[Task] = [];
    has seen: dict[str, bool] = {};

    can scan with Task entry {
        if here.task_id in self.seen {
            skip;           # diamond revisit / cycle policy: decide once,
        }                   # keep sibling branches alive
        self.seen[here.task_id] = True;
        if here.holders > 1 or here.done {
            self.preserved.append(here);    # shared or completed island
            skip;                           # never descend past it
        }
        self.doomed.append(here);
        visit [->:Tracks:->];
    }
}

obj TaskBoard {
    has tasks: dict[str, Task];

    def add(task_id: str, title: str, done: bool = False) -> Task {
        fresh = Task(task_id=task_id, title=title, done=done);
        self.tasks[task_id] = fresh;
        return fresh;
    }

    def attach(parent_id: str, child_id: str) -> bool {
        parent = self.tasks.get(parent_id);
        child = self.tasks.get(child_id);
        if child is None or parent is None {
            return False;                   # tolerate unknown refs
        }
        parent +>:Tracks:+> child;
        child.holders += 1;
        child.parent_id = parent_id;
        return True;
    }

    """Delete *task_id* + open exclusive subtree; returns preserved ids."""
    def delete_task(task_id: str) -> list[str] {
        head = self.tasks.get(task_id);
        if head is None {
            return [];
        }
        if head.done {
            return [head.task_id];          # preserving no-op per source
        }
        # Phase COLLECT -- walk first, mutate never.
        scan = head spawn DeleteScan();
        doomed = scan.doomed;
        preserved = scan.preserved;

        # Phase APPLY -- strictly after the walk finished.
        for dead in doomed {
            kids = [dead ->:Tracks:->] as list[Task];
            for child in kids {
                child.holders -= 1;         # dying holder releases its hold
                dead del ->:Tracks:-> child;
            }
        }
        for victim in doomed {
            vid = victim.task_id;   # capture before del unbinds the ref
            del victim;
            _gone = self.tasks.pop(vid, None);
        }
        # sweeper pass: clear dangling back-references
        for t in self.tasks.values() as list[Task] {
            if t.parent_id is not None and not (t.parent_id in self.tasks) {
                t.parent_id = None;
            }
        }
        return sorted(s.task_id for s in preserved);
    }

    def exists(task_id: str) -> bool {
        return task_id in self.tasks;
    }

    def parent_of(task_id: str) -> str | None {
        t = self.tasks.get(task_id);
        if t is None {
            return None;
        }
        return t.parent_id;
    }

    def titles -> list[str] {
        return sorted(t.title for t in self.tasks.values());
    }
}

"""Build a fresh deterministic board; creation order = fixture order."""
def load_graph(spec: list[tuple[str, str, bool]],
               links: list[tuple[str, str]]) -> TaskBoard {
    board = TaskBoard(tasks={});
    for row in spec {
        _made = board.add(row[0], row[1], row[2]);
    }
    for pair in links {
        _ok = board.attach(pair[0], pair[1]);
    }
    return board;
}

test "deletes_open_branch_preserves_done_island" {
    board = load_graph(
        spec=[("epic", "Epic", False), ("design", "Design", False),
              ("wireframes", "Wireframes", True), ("hifi", "Hi-Fi", False),
              ("backend", "Backend", False), ("api", "API", False)],
        links=[("epic", "design"), ("design", "wireframes"),
               ("wireframes", "hifi"), ("epic", "backend"),
               ("backend", "api")]
    );
    preserved = board.delete_task("design");
    assert preserved == ["wireframes"];      # island root only
    assert not board.exists("design");
    assert board.exists("wireframes") and board.exists("hifi");
    assert board.exists("backend") and board.exists("api");
    assert board.parent_of("wireframes") is None;   # sweep cleaned it
}

test "shared_task_spared_then_deleted_with_last_holder" {
    board = load_graph(
        spec=[("epic", "Epic", False), ("backend", "Backend", False),
              ("shared_lib", "Shared Lib", False), ("epic2", "Epic 2", False)],
        links=[("epic", "backend"), ("epic", "shared_lib"),
               ("epic2", "shared_lib")]
    );
    preserved = board.delete_task("epic");
    assert "shared_lib" in preserved;
    assert board.exists("shared_lib");
    second = board.delete_task("epic2");     # last holder gone -> deleted
    assert second == [];
    assert not board.exists("shared_lib");
}

test "done_root_noop_and_unknown_ids" {
    board = load_graph(
        spec=[("t1", "T1", False), ("done1", "Done", True)],
        links=[]
    );
    assert board.delete_task("ghost") == [];
    assert board.delete_task("done1") == ["done1"];   # preserving no-op
    assert board.exists("done1");
}
