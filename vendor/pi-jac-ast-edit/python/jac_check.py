"""Post-edit `jac check`: report only the diagnostics an edit introduced.

`jac check --nowarn <file>` runs before and after the write. Diagnostics are
compared by (code, message) as a multiset, since line numbers shift with the
edit. The "before" run is cached by file path + content hash, and every
"after" run is stored as the baseline for the next edit of the same content,
so a chain of edits costs one check each after the first.

Environment:
    JAC_AST_EDIT_CHECK=0           disable the post-edit check
    JAC_AST_EDIT_CHECK_TIMEOUT=30  seconds per `jac check` run
    JAC_AST_EDIT_CHECK_MAX=5       max new diagnostics shown
    JAC_AST_EDIT_JAC=jac           jac executable
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import time
from collections import Counter
from pathlib import Path

ANSI_RE = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
# "✖ Error: error[E1055]: msg", "error[E0001]: msg", "✖ Error: msg" (no code)
HEADER_RE = re.compile(r"^\s*(?:✖\s*Error:\s*)?error(?:\[(?P<code>[A-Z]\d+)\])?:\s*(?P<msg>.*)$"
                       r"|^\s*✖\s*Error:\s*(?P<msg2>.*)$")
LOC_RE = re.compile(r"^\s*-->\s*(?P<file>.+?):(?P<line>\d+):(?P<col>\d+)")
SNIPPET_RE = re.compile(r"^\s*(?P<n>\d+)?\s*\|(?P<text>.*)$")
END_RE = re.compile(r"^(=+|_+|\s*Checking |.* (FAILED|PASSED) \[)")

MAX_TOTAL_CHARS = 2000


def enabled() -> bool:
    return os.environ.get("JAC_AST_EDIT_CHECK", "1").strip().lower() not in ("0", "false", "no", "off")


def _timeout() -> float:
    try:
        return float(os.environ.get("JAC_AST_EDIT_CHECK_TIMEOUT", "30"))
    except ValueError:
        return 30.0


def _max_shown() -> int:
    try:
        return max(1, int(os.environ.get("JAC_AST_EDIT_CHECK_MAX", "5")))
    except ValueError:
        return 5


def parse_diagnostics(output: str) -> list[dict]:
    """Error blocks from `jac check` output, in order:
    {code, message, line, col, source, caret, guide}."""
    diags: list[dict] = []
    cur: dict | None = None
    for raw in ANSI_RE.sub("", output).splitlines():
        m = HEADER_RE.match(raw)
        if m and not raw.lstrip().startswith("|"):
            cur = {"code": m.group("code") or "", "message": (m.group("msg") or m.group("msg2") or "").strip(),
                   "line": None, "col": None, "source": None, "caret": None, "guide": None}
            diags.append(cur)
            continue
        if cur is None:
            continue
        if raw.lstrip().startswith(("⚠", "warning")) or END_RE.match(raw):
            cur = None
            continue
        lm = LOC_RE.match(raw)
        if lm and cur["line"] is None:
            cur["line"], cur["col"] = int(lm.group("line")), int(lm.group("col"))
            continue
        sm = SNIPPET_RE.match(raw)
        if sm and cur["line"] is not None:
            if sm.group("n") and int(sm.group("n")) == cur["line"]:
                cur["source"] = sm.group("text")[1:] if sm.group("text").startswith(" ") else sm.group("text")
            elif not sm.group("n") and cur["source"] is not None and cur["caret"] is None and "^" in sm.group("text"):
                cur["caret"] = sm.group("text")[1:] if sm.group("text").startswith(" ") else sm.group("text")
            continue
        stripped = raw.strip()
        if stripped.startswith("→") and "jac guide" in stripped:
            cur["guide"] = stripped.lstrip("→ ").strip()
    return diags


def run_check(path: Path, cwd: str | None = None) -> dict:
    """{ok, diags, seconds, error?} for one `jac check --nowarn` run. A run
    killed by a signal (seen while the jac binary unpacks its runtime) is
    retried once."""
    t0 = time.monotonic()
    res = _run_check_once(path, cwd)
    if not res["ok"] and res.get("signal"):
        res = _run_check_once(path, cwd)
    res["seconds"] = time.monotonic() - t0
    res.pop("signal", None)
    return res


def _run_check_once(path: Path, cwd: str | None) -> dict:
    jac = os.environ.get("JAC_AST_EDIT_JAC", "jac")
    t0 = time.monotonic()
    try:
        proc = subprocess.run([jac, "check", "--nowarn", str(path)], cwd=cwd or str(path.parent),
                              capture_output=True, text=True, timeout=_timeout())
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": f"timed out after {_timeout():g}s", "seconds": time.monotonic() - t0}
    except OSError as e:
        return {"ok": False, "error": f"could not run {jac}: {e.strerror or e}", "seconds": time.monotonic() - t0}
    out = proc.stdout + "\n" + proc.stderr
    diags = parse_diagnostics(out)
    if proc.returncode != 0 and not diags:
        last = next((ln.strip() for ln in reversed(ANSI_RE.sub("", out).splitlines()) if ln.strip()), "")
        return {"ok": False, "error": f"jac check exited {proc.returncode}: {last[:200]}",
                "seconds": time.monotonic() - t0, "signal": proc.returncode < 0}
    return {"ok": True, "diags": diags, "seconds": time.monotonic() - t0}


def cache_root() -> Path:
    """$JAC_AST_EDIT_CACHE_DIR, else $XDG_CACHE_HOME/pi-jac-ast-edit (~/.cache)."""
    if os.environ.get("JAC_AST_EDIT_CACHE_DIR"):
        return Path(os.environ["JAC_AST_EDIT_CACHE_DIR"])
    base = os.environ.get("XDG_CACHE_HOME") or os.path.join(os.path.expanduser("~"), ".cache")
    return Path(base) / "pi-jac-ast-edit"


def _cache_file(path: Path, content: bytes) -> Path:
    key = hashlib.sha256(str(path.resolve()).encode() + b"\0" + content).hexdigest()[:24]
    return cache_root() / "check" / f"{key}.json"


def cached_diags(path: Path, content: bytes) -> list[dict] | None:
    try:
        data = json.loads(_cache_file(path, content).read_text())
        return data if isinstance(data, list) else None
    except (OSError, ValueError):
        return None


def store_diags(path: Path, content: bytes, diags: list[dict]) -> None:
    f = _cache_file(path, content)
    tmp = f.with_name(f"{f.name}.{os.getpid()}.tmp")
    try:
        f.parent.mkdir(parents=True, exist_ok=True)
        tmp.write_text(json.dumps(diags))
        os.replace(tmp, f)
    except OSError:
        try:
            tmp.unlink()
        except OSError:
            pass


def new_diagnostics(before: list[dict], after: list[dict], changed_lines: set[int] | None = None) -> list[dict]:
    """Diagnostics in `after` beyond the (code, message) counts of `before`.
    When a key gained k instances, the k shown are those on changed lines
    first, then in file order."""
    budget = Counter((d["code"], d["message"]) for d in after)
    budget.subtract(Counter((d["code"], d["message"]) for d in before))
    changed_lines = changed_lines or set()
    ranked = sorted(enumerate(after), key=lambda t: (t[1].get("line") not in changed_lines, t[0]))
    picked = []
    for i, d in ranked:
        key = (d["code"], d["message"])
        if budget[key] > 0:
            budget[key] -= 1
            picked.append((i, d))
    return [d for _, d in sorted(picked, key=lambda t: t[0])]


def format_report(display_path: str, new: list[dict], total_after: int, fixed: int,
                  error: str | None = None, no_baseline: bool = False) -> str:
    """The `jac check` section appended to an edit result. no_baseline: the
    pre-edit check failed, so `new` holds every error of the edited file."""
    if error:
        return f"jac check: not run ({error})"
    if no_baseline and new:
        head = f"jac check: {len(new)} error{'s' if len(new) != 1 else ''} (no pre-edit baseline)"
        return _format_list(display_path, new, head)
    if not new:
        tail = []
        if fixed:
            tail.append(f"{fixed} fixed")
        if total_after:
            tail.append(f"{total_after} pre-existing error{'s remain' if total_after != 1 else ' remains'}")
        return "jac check: no new errors" + (f" ({', '.join(tail)})" if tail else "")
    head = f"jac check: {len(new)} new error{'s' if len(new) != 1 else ''}"
    head += f" (file has {total_after} total)" if total_after != len(new) else ""
    return _format_list(display_path, new, head)


def _format_list(display_path: str, new: list[dict], head: str) -> str:
    shown = new[: _max_shown()]
    lines = [head + ":"]
    for d in shown:
        code = f"error[{d['code']}]" if d["code"] else "error"
        loc = f"{display_path}:{d['line']}:{d['col']}" if d.get("line") else display_path
        block = [f"{code} {loc}: {d['message'][:300]}"]
        if d.get("source") is not None:
            block.append(f"  {d['source'].rstrip()[:200]}")
            if d.get("caret"):
                block.append(f"  {d['caret'].rstrip()[:200]}")
        if d.get("guide"):
            block.append(f"  → {d['guide']}")
        lines.extend(block)
    if len(new) > len(shown):
        lines.append(f"… {len(new) - len(shown)} more new error(s); run `jac check {display_path}` to see all")
    text = "\n".join(lines)
    if len(text) > MAX_TOTAL_CHARS:
        text = text[: MAX_TOTAL_CHARS - 40].rsplit("\n", 1)[0] + "\n… (truncated; run jac check)"
    return text
