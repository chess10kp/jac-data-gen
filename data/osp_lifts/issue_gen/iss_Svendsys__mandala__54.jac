"""Svendsys/mandala#54 — Wave dependency ready set."""

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
