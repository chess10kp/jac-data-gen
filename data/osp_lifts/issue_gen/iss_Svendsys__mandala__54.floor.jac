"""Svendsys/mandala#54 — Wave dependency ready set."""
import from __future__ { annotations }
class WaveBoard {
    def init(self: WaveBoard) -> None {
        self._tasks: set[str] = `set();
        self._blockers: dict[(str, set[str])] = {};
        self._done: set[str] = `set();
    }
}
def load_wave_board(
    tasks: list[str], deps: list[tuple[(str, str)]], done: list[str]
) -> WaveBoard {
    b = WaveBoard();
    for tid in tasks {
        b._tasks.add(tid);
        b._blockers.setdefault(tid, `set());
    }
    for (blocker, task) in deps {
        if ((blocker not in b._tasks) or (task not in b._tasks)) {
            continue;
        }
        b._blockers[task].add(blocker);
    }
    b._done = `set(done);
    return b;
}
def ready_set(board: WaveBoard) -> list[str] {
    ready: list[str] = [];
    for tid in sorted(board._tasks) {
        if (tid in board._done) {
            continue;
        }
        pending = [
            b
            for b in board._blockers[tid]
            if (b not in board._done)
        ];
        if not pending {
            ready.append(tid);
        }
    }
    return ready;
}
def next_wave(board: WaveBoard) -> list[str] {
    return ready_set(board);
}
def mark_done(board: WaveBoard, task_id: str) -> None {
    if (task_id in board._tasks) {
        board._done.add(task_id);
    }
}

