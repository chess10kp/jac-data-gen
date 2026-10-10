"""Append-only log of repair trajectories: attempt -> feedback -> fix chains.

The repair loops (osp_repair_wave, jachacks_repair, idiomize_repair) used to
keep only the final green program, discarding every intermediate attempt and
the compiler/test feedback that drove each fix. Those chains are exactly the
"read the error, fix the code" supervision a coding model needs, so they are
logged here as a sidecar; the loops' existing outputs are unchanged.

One JSONL line per finished trajectory, under data/trajectories/<pipeline>.jsonl
(override the directory with TRAJ_LOG_DIR):

  {"id", "pipeline", "task", "fixer", "system",
   "start": {"code", "feedback"},            # the broken program + its feedback
   "steps": [{"round", "user", "response",   # exact fix prompt + raw reply
              "candidate", "verdict",        # extracted program + gate verdict
              "feedback"}],                  # gate output shown to the next round
   "outcome": "pass" | "fail", "ts"}

Failed trajectories are kept too: their steps are negatives (DPO `rejected`
sides) and their feedback is still a realistic error distribution. Consumers
must train only on steps whose candidate eventually led to `pass`.
"""
from __future__ import annotations

import fcntl
import json
import os
import threading
from datetime import datetime
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parents[2]
DEFAULT_DIR = REPO / "data" / "trajectories"


class TrajectoryLog:
    def __init__(self, pipeline: str, fixer: str, system: str = "",
                 path: Path | None = None):
        root = Path(os.environ.get("TRAJ_LOG_DIR", str(DEFAULT_DIR)))
        self.path = path or root / f"{pipeline}.jsonl"
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.pipeline = pipeline
        self.fixer = fixer
        self.system = system
        self._lock = threading.Lock()

    def start(self, rid: str, task: str, code: str | None,
              feedback: Any) -> dict:
        return {"id": rid, "pipeline": self.pipeline, "task": task,
                "fixer": self.fixer, "system": self.system,
                "start": {"code": code, "feedback": feedback}, "steps": []}

    @staticmethod
    def step(traj: dict, round_no: int, user: str, response: str | None,
             candidate: str | None, verdict: str,
             feedback: Any = None) -> dict:
        s = {"round": round_no, "user": user, "response": response,
             "candidate": candidate, "verdict": verdict, "feedback": feedback}
        traj["steps"].append(s)
        return s

    def finish(self, traj: dict, outcome: str) -> None:
        """Write one trajectory. Trajectories with no model step are dropped."""
        if not traj["steps"]:
            return
        line = json.dumps({**traj, "outcome": outcome,
                           "ts": datetime.now().isoformat()},
                          ensure_ascii=False) + "\n"
        # threads share the lock; parallel shard processes share the flock
        with self._lock, self.path.open("a") as fh:
            fcntl.flock(fh, fcntl.LOCK_EX)
            fh.write(line)
            fh.flush()
            fcntl.flock(fh, fcntl.LOCK_UN)
