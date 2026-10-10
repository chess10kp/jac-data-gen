#!/usr/bin/env python3
"""Hidden CLI persistence check. Usage: behavioral.py <workspace_dir>

Copies the workspace to a fresh temp dir (jac's graph store is keyed by cwd, so
this starts from an empty graph) and drives the CLI the request specifies with
a sequence of separate `jac run main.jac <args>` processes, so state must
persist on root between runs. Last stdout line is a JSON verdict
{"run": bool, "behavioral": bool, "failures": [...]}; exit 0 iff both true.
Output matching is tolerant (case-insensitive substrings / numbers).
"""
import json, re, shutil, subprocess, sys, tempfile

FAIL: list = []
RUN_OK = [True]


def check(cond, msg):
    if not cond:
        FAIL.append(msg)
    return bool(cond)


class Cli:
    def __init__(self, ws):
        self.dir = tempfile.mkdtemp(prefix="beh_")
        shutil.copytree(ws, self.dir, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns(".jac", "node_modules", "__pycache__"))

    def __call__(self, *args):
        try:
            p = subprocess.run(["jac", "run", "main.jac", *map(str, args)], cwd=self.dir,
                               stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=180)
            out, rc, err = p.stdout, p.returncode, p.stderr
        except subprocess.TimeoutExpired:
            out, rc, err = "", 124, "timeout"
        # drop jac's own progress chatter
        lines = [l for l in out.splitlines() if l.strip() and not l.startswith(("Preparing application",
                 "  Restoring", "  Compiling", "Initializing application", "WARNING", "INFO"))]
        text = "\n".join(lines)
        if rc != 0:
            RUN_OK[0] = False
            FAIL.append(f"`jac run main.jac {' '.join(map(str, args))}` exited {rc}: {err[-400:]}")
        sys.stderr.write(f"$ {' '.join(map(str, args))}\n{text}\n")
        return text


def nums(text):
    return [float(x) for x in re.findall(r"-?\d+(?:\.\d+)?", text)]


def has(text, *subs):
    t = text.lower()
    return all(s.lower() in t for s in subs)


def main():
    cli = Cli(sys.argv[1])
    try:
        checks(cli)
    except Exception as e:
        FAIL.append(f"exception: {type(e).__name__}: {e}")
    verdict = {"run": RUN_OK[0], "behavioral": not FAIL, "failures": FAIL[:20]}
    print(json.dumps(verdict))
    sys.exit(0 if verdict["run"] and verdict["behavioral"] else 1)


def checks(cli):
    cli("add", "fern", 3, "2026-01-01")
    cli("add", "cactus", 14, "2026-01-01")
    out = cli("due", "2026-01-03")
    check(has(out, "nothing due"), f"due 01-03 should be 'nothing due', got {out!r}")
    out = cli("due", "2026-01-04")
    check(has(out, "fern") and not has(out, "cactus"), f"due 01-04 should list only fern, got {out!r}")
    cli("water", "fern", "2026-01-04")
    out = cli("due", "2026-01-05")
    check(has(out, "nothing due"), f"after watering fern, due 01-05 should be empty, got {out!r}")
    out = cli("due", "2026-01-15")
    check(has(out, "fern") and has(out, "cactus"), f"due 01-15 should list both, got {out!r}")
    lines = [l.strip().lower() for l in out.splitlines() if l.strip().lower() in ("fern", "cactus")]
    check(lines == ["cactus", "fern"], f"due list should be alphabetical one per line, got {lines!r}")
    cli("add", "fern", 2, "2026-01-14")
    out = cli("due", "2026-01-15")
    check(has(out, "cactus") and not has(out, "fern"), f"re-added fern should not be due 01-15, got {out!r}")
    out = cli("water", "orchid", "2026-01-15")
    check(has(out, "no such plant"), f"watering unknown plant should say 'no such plant', got {out!r}")


if __name__ == "__main__":
    main()
