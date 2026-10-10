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
    cli("add-book", "111", 2, "Dune", "Messiah")
    out = cli("checkout", "ann", "111", "2026-02-01")
    check(has(out, "due 2026-02-15"), f"ann checkout should be due 2026-02-15, got {out!r}")
    out = cli("checkout", "bob", "111", "2026-02-03")
    check(has(out, "due 2026-02-17"), f"bob checkout should be due 2026-02-17, got {out!r}")
    out = cli("checkout", "cy", "111", "2026-02-03")
    check(has(out, "unavailable"), f"third checkout of 2 copies should be unavailable, got {out!r}")
    out = cli("available", "111")
    check(nums(out)[-1:] == [0.0], f"available should be 0, got {out!r}")
    out = cli("overdue", "2026-02-16")
    check(has(out, "ann", "111", "2026-02-15") and not has(out, "bob"), f"only ann overdue on 02-16, got {out!r}")
    out = cli("return", "ann", "111")
    check(has(out, "returned"), f"return should print returned, got {out!r}")
    out = cli("available", "111")
    check(nums(out)[-1:] == [1.0], f"available should be 1 after return, got {out!r}")
    out = cli("overdue", "2026-02-16")
    check(has(out, "none overdue"), f"nothing overdue after return, got {out!r}")
    out = cli("return", "ann", "111")
    check(has(out, "no such loan"), f"second return should print no such loan, got {out!r}")


if __name__ == "__main__":
    main()
