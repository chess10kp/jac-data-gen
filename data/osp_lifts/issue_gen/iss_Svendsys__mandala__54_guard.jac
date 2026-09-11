"""Guard: Svendsys/mandala#54."""

obj WaveBoard {
    has tasks: dict[str, WaveTask] = {};
    has done: dict[str, bool] = {};
}
node WaveTask { has tid: str; }
edge Requires {}

def load_wave_board(
    tasks: list[str],
    deps: list[tuple[str, str]],
    done: list[str],
) -> WaveBoard {
    b = WaveBoard();
    for tid in tasks {
        if tid not in b.tasks {
            nd = WaveTask(tid=tid);
            root ++> nd;
            b.tasks[tid] = nd;
        }
    }
    for (blocker, task) in deps {
        blk = b.tasks.get(blocker, None);
        tgt = b.tasks.get(task, None);
        if blk is None or tgt is None { continue; }
        blk +>:Requires:+> tgt;
    }
    for d in done { b.done[d] = True; }
    return b;
}

def ready_set(board: WaveBoard) -> list[str] {
    ready: list[str] = [];
    for (tid, nd) in board.tasks.items() {
        if board.done.get(tid, False) { continue; }
        pending = False;
        for blk in [nd <-:Requires:<-][?:WaveTask] {
            if not board.done.get(blk.tid, False) { pending = True; }
        }
        if not pending { ready.append(tid); }
    }
    return sorted(ready);
}

def next_wave(board: WaveBoard) -> list[str] {
    return ready_set(board);
}

def mark_done(board: WaveBoard, task_id: str) {
    if task_id in board.tasks { board.done[task_id] = True; }
}

test "wave ready progression" {
    b = load_wave_board(
        ["w1a", "w1b", "w2a", "w2b"],
        [("w1a", "w2a"), ("w1b", "w2a"), ("w2a", "w2b")],
        ["w1a"],
    );
    assert ready_set(b) == ["w1b"];
    mark_done(b, "w1b");
    assert next_wave(b) == ["w2a"];
}

test "diamond fan-out ready set" {
    b = load_wave_board(
        ["hub", "left", "right", "leaf"],
        [
            ("hub", "left"),
            ("hub", "right"),
            ("left", "leaf"),
            ("right", "leaf"),
        ],
        ["hub"],
    );
    assert ready_set(b) == ["left", "right"];
}

test "all done yields empty wave" {
    b = load_wave_board(["solo"], [], ["solo"]);
    assert next_wave(b) == [];
}
