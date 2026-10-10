"""Compact view of what an edit changed, appended to the edit result.

For every changed region (a line diff of the file before vs after the batch)
the view shows the smallest enclosing symbol of the NEW file:

- a symbol of at most SHORT_SYMBOL lines is shown whole;
- a longer one shows its first line (the signature), each changed region
  with CONTEXT lines around it, and its last line; skipped spans collapse into
  `… N unchanged lines (read path:a-b) …` markers with the exact read range.

Changes outside any symbol (imports, removed top-level symbols) show the
changed lines with context. The whole view is capped at MAX_LINES code lines
across all ops; a final marker names the next range to read. Output has no
line-number gutters, so code copied from it can be used as an anchor.
"""
from __future__ import annotations

import difflib

SHORT_SYMBOL = 30
CONTEXT = 3
MAX_LINES = 60
# Members are shown inside their owner; imports are file-level.
SKIP_KINDS = {"has", "member", "import"}


def changed_regions(old: str, new: str) -> list[tuple[int, int]]:
    """0-based [start, end) line ranges in `new` that differ from `old`.
    A pure deletion is an empty range at the line after the cut."""
    sm = difflib.SequenceMatcher(None, old.split("\n"), new.split("\n"), autojunk=False)
    return [(j1, j2) for tag, _i1, _i2, j1, j2 in sm.get_opcodes() if tag != "equal"]


def changed_line_numbers(old: str, new: str) -> set[int]:
    """1-based lines of `new` that were added or modified."""
    out: set[int] = set()
    for a, b in changed_regions(old, new):
        out.update(range(a + 1, max(a, b) + 1 if b > a else a + 2))
    return out


def _container(symbols, start: int, end: int):
    """Smallest symbol (start_line, end_line, kind, qualified) covering lines
    [start, end) — for an empty range, the lines on both sides of the cut."""
    lo, hi = (start, end - 1) if end > start else (start - 1, start)
    best = None
    for s in symbols:
        if s[2] in SKIP_KINDS:
            continue
        if s[0] <= lo and s[1] >= hi and (best is None or s[1] - s[0] < best[1] - best[0]):
            best = s
    return best


def _windows(first: int, last: int, regions, always=()) -> list[tuple[int, int]]:
    """Merged inclusive line windows within [first, last]."""
    wins = [(ln, ln) for ln in always]
    for a, b in regions:
        hi = b - 1 if b > a else a
        wins.append((max(first, a - CONTEXT), min(last, hi + CONTEXT)))
    wins.sort()
    merged: list[list[int]] = []
    for a, b in wins:
        # a gap of a single line costs less to show than a marker
        if merged and a <= merged[-1][1] + 2:
            merged[-1][1] = max(merged[-1][1], b)
        else:
            merged.append([a, b])
    return [(a, b) for a, b in merged]


def render(old: str, new: str, display_path: str, symbols) -> str:
    """symbols: [(start_line0, end_line0, kind, qualified)] of the NEW file."""
    lines = new.split("\n")
    n = len(lines) - 1 if lines and lines[-1] == "" else len(lines)
    if n <= 0:
        return f"[{display_path}] (file is empty)"
    regions = changed_regions(old, new)
    if not regions:
        return ""

    # group regions by enclosing symbol; regions outside symbols stand alone
    blocks: dict[tuple, list[tuple[int, int]]] = {}
    for a, b in regions:
        a, b = min(a, n), min(b, n)
        sym = _container(symbols, a, b)
        key = sym if sym else (a, max(a, b - 1), None, None)
        blocks.setdefault(key, []).append((a, b))

    out: list[str] = []
    budget = MAX_LINES
    keys = sorted(blocks, key=lambda k: (k[0], k[1]))
    for bi, key in enumerate(keys):
        first, last, kind, qual = key
        regs = blocks[key]
        if kind is None:  # outside any symbol: changed lines + context
            first, last = max(0, first - CONTEXT), min(n - 1, last + CONTEXT)
            wins = [(first, last)]
            out.append(f"[{display_path}:{first + 1}-{last + 1}]")
        else:
            out.append(f"[{display_path}:{first + 1}-{last + 1} {kind} {qual}]")
            if last - first + 1 <= SHORT_SYMBOL:
                wins = [(first, last)]
            else:
                wins = _windows(first, last, regs, always=(first, last))
        prev = first - 1
        for a, b in wins:
            if a > prev + 1:
                gap = a - prev - 1
                out.append(f"… {gap} unchanged line{'s' if gap != 1 else ''} "
                           f"(read {display_path}:{prev + 2}-{a}) …")
            for ln in range(a, b + 1):
                if budget == 0:
                    rest = keys[bi + 1:]
                    more = ""
                    if rest:
                        spans = ", ".join(f"{display_path}:{k[0] + 1}-{k[1] + 1}" for k in rest[:3])
                        more = (f"; {len(rest)} more changed region{'s' if len(rest) != 1 else ''}: "
                                f"{spans}{', …' if len(rest) > 3 else ''}")
                    out.append(f"… view capped at {MAX_LINES} lines "
                               f"(next: read {display_path}:{ln + 1}-{last + 1}{more}) …")
                    return "\n".join(out)
                out.append(lines[ln].rstrip("\r"))
                budget -= 1
            prev = b
    return "\n".join(out)
