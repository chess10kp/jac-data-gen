#!/usr/bin/env python3
"""Corruption-safe JSONL I/O for long pipeline runs.

Fixes three observed failure classes:
  1. NUL-corrupted tails from power loss crash-looping readers
     (json.loads on every line, bare except -> continue).
  2. flush-without-fsync appends lost on power loss.
  3. Non-atomic master rewrites (os.replace then open(w) -> crash = no master).

API:
  append(path, obj)          locked append + flush + fsync, strict valid JSON only
  read_strict(path)          stops on first corrupt line, raises CorruptLine
                             (byte offset + quarantine hint) — never silent
  read_tolerant(path)        yields (ok, obj_or_line); corrupt lines reported
  atomic_write(path, lines)  temp file + fsync + os.replace; old file survives
"""
from __future__ import annotations
import fcntl, json, os, tempfile
from pathlib import Path


class CorruptLine(Exception):
    def __init__(self, path, lineno: int, offset: int, line: str):
        self.path, self.lineno, self.offset = path, lineno, offset
        self.line = line
        super().__init__(
            f"{path}:{lineno} (offset {offset}) corrupt JSONL line: {line[:80]!r}")


def _valid(line: str) -> bool:
    try:
        json.loads(line)
        return True
    except Exception:  # noqa: BLE001
        return False


def append(path: str | Path, obj: dict) -> None:
    """Locked, durable append of one JSON object. Crash-safe: fsync'd line."""
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    line = json.dumps(obj) + "\n"
    with open(p, "a") as f:
        fcntl.flock(f.fileno(), fcntl.LOCK_EX)
        try:
            f.write(line)
            f.flush()
            os.fsync(f.fileno())
        finally:
            fcntl.flock(f.fileno(), fcntl.LOCK_UN)


def read_strict(path: str | Path) -> list[dict]:
    """Read every line as JSON. Stop and raise at the FIRST corrupt line —
    silent skips are how corrupt tails silently shrink datasets. A corrupt
    FINAL line (crash mid-write / NUL tail) is quarantined to <path>.bad and
    the file is truncated to the last good line, then reading succeeds."""
    p = Path(path)
    if not p.exists():
        return []
    raw_lines = p.read_bytes().split(b"\n")
    trailing_nl = raw_lines and raw_lines[-1] == b""
    if trailing_nl:
        raw_lines = raw_lines[:-1]
    out = []
    for i, raw in enumerate(raw_lines):
        if not raw.strip():
            continue
        if b"\x00" in raw or not _valid(raw.decode(errors="replace")):
            if i == len(raw_lines) - 1 and not trailing_nl:
                # corrupt tail: quarantine it, truncate to good prefix
                p.with_suffix(p.suffix + ".bad").write_bytes(raw)
                good = p.read_bytes()
                good = good[: good.rfind(b"\n") + 1] if b"\n" in good else b""
                atomic_write(p, [l for l in good.decode(errors="replace").splitlines()])
                return out
            off = sum(len(r) + 1 for r in raw_lines[:i])
            raise CorruptLine(p, i + 1, off, raw.decode(errors="replace"))
        out.append(json.loads(raw))
    return out


def read_tolerant(path: str | Path):
    """Yield (True, obj) or (False, bad_line_text). For repair tools."""
    p = Path(path)
    if not p.exists():
        return
    with open(p, "rb") as f:
        for i, raw in enumerate(f, 1):
            try:
                if b"\x00" in raw:
                    raise ValueError("NUL")
                yield True, json.loads(raw)
            except Exception:  # noqa: BLE001
                yield False, raw.decode(errors="replace")[:200]


def atomic_write(path: str | Path, lines: list[str]) -> None:
    """Crash-safe full rewrite: temp in same dir + fsync + atomic replace."""
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=p.parent, prefix=p.name + ".tmp")
    try:
        with os.fdopen(fd, "w") as f:
            f.write("\n".join(lines) + "\n")
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, p)
        _fsync_dir(p.parent)
    except BaseException:
        try: os.unlink(tmp)
        except OSError: pass
        raise


def _fsync_dir(d: Path) -> None:
    try:
        fd = os.open(d, os.O_DIRECTORY)
        try: os.fsync(fd)
        finally: os.close(fd)
    except OSError:
        pass
