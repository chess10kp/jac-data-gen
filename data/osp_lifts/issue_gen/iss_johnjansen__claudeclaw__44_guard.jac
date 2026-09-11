"""Guard: johnjansen/claudeclaw#44."""

node Job { has jid: str; }
edge DependsOn {}

obj JobBoard {
    has jobs: dict[str, Job] = {};
    has done: dict[str, bool] = {};
    has failed: dict[str, bool] = {};
}

walker CycleProbe {
    has visited: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has errors: list[tuple[str, str]] = [];

    can step with Job entry {
        if here.jid in self.visited { skip; }
        self.visited[here.jid] = True;
        self.stack[here.jid] = True;
        for prereq in [here <-:DependsOn:<-][?:Job] {
            if prereq.jid in self.stack {
                self.errors.append((here.jid, prereq.jid));
            } else {
                if not (prereq.jid in self.visited) { visit [prereq]; }
            }
        }
        self.stack[here.jid] = False;
    }
}

def load_job_board(
    jobs: list[str],
    deps: list[tuple[str, str]],
    done: list[str] | None = None,
    failed: list[str] | None = None,
) -> JobBoard {
    b = JobBoard();
    for jid in jobs {
        nd = Job(jid=jid);
        root ++> nd;
        b.jobs[jid] = nd;
    }
    for (prereq, job) in deps {
        p = b.jobs.get(prereq, None);
        j = b.jobs.get(job, None);
        if p is not None and j is not None { p +>:DependsOn:+> j; }
    }
    for d in (done or []) { b.done[d] = True; }
    for f in (failed or []) { b.failed[f] = True; }
    return b;
}

def detect_cycles(board: JobBoard) -> list[tuple[str, str]] {
    errors: list[tuple[str, str]] = [];
    visited: dict[str, bool] = {};
    for k in sorted(board.jobs.keys()) {
        if k in visited { continue; }
        w = board.jobs[k] spawn CycleProbe(visited=visited, stack={}, errors=[]);
        errors = errors + w.errors;
        visited = w.visited;
    }
    return sorted(errors);
}

def get_ready_jobs(board: JobBoard) -> list[str] {
    ready: list[str] = [];
    for (jid, nd) in board.jobs.items() {
        if board.done.get(jid, False) or board.failed.get(jid, False) { continue; }
        blocked = False;
        for prereq in [nd <-:DependsOn:<-][?:Job] {
            if not board.done.get(prereq.jid, False) and not board.failed.get(prereq.jid, False) {
                blocked = True;
            }
        }
        if not blocked { ready.append(jid); }
    }
    return sorted(ready);
}

def execution_order(board: JobBoard) -> list[str] {
    indeg: dict[str, int] = {};
    rev: dict[str, list[str]] = {};
    for jid in board.jobs.keys() {
        indeg[jid] = 0;
        rev[jid] = [];
    }
    for (jid, nd) in board.jobs.items() {
        for prereq in [nd <-:DependsOn:<-][?:Job] {
            indeg[jid] += 1;
            rev[prereq.jid].append(jid);
        }
    }
    frontier: list[str] = [];
    for jid in sorted(board.jobs.keys()) {
        if indeg[jid] == 0 { frontier.append(jid); }
    }
    order: list[str] = [];
    while len(frontier) > 0 {
        cur = frontier.pop(0);
        order.append(cur);
        for nxt in sorted(rev.get(cur, [])) {
            indeg[nxt] -= 1;
            if indeg[nxt] == 0 { frontier.append(nxt); }
        }
    }
    return order if len(order) == len(board.jobs) else [];
}

test "chain execution order" {
    b = load_job_board(
        ["build", "test", "deploy"],
        [("build", "test"), ("test", "deploy")],
    );
    assert get_ready_jobs(b) == ["build"];
    assert execution_order(b) == ["build", "test", "deploy"];
    assert detect_cycles(b) == [];
}

test "cycle detected" {
    b = load_job_board(["a", "b"], [("a", "b"), ("b", "a")]);
    assert detect_cycles(b) == [("b", "a")];
    assert execution_order(b) == [];
}

test "diamond ready after hub done" {
    b = load_job_board(
        ["hub", "left", "right", "leaf"],
        [
            ("hub", "left"),
            ("hub", "right"),
            ("left", "leaf"),
            ("right", "leaf"),
        ],
        done=["hub"],
    );
    assert get_ready_jobs(b) == ["left", "right"];
}
