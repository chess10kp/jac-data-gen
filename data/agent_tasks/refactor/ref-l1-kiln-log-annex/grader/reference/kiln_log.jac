"""Ceramics kiln log: firings, their losses and per-cone yield summaries.

Declarations only; bodies live in kiln_log.impl.jac.
"""

obj Firing {
    has batch: str;
    has cone: int;
    has pieces: int;
    has cracked: int = 0;
    has glaze_faults: int = 0;
    has aborted: bool = False;

    def losses -> int;
    def yield_pct -> int;
    def abort -> bool;
}

def firing_line(f: Firing) -> str;
def cone_yield(firings: list[Firing], cone: int) -> int;
def worst_batch(firings: list[Firing]) -> str;
