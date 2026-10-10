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
    cli("add", "kx-101")
    out = cli("fill", "KX-101", 20000, 50)
    check(has(out, "ok") and not has(out, "error"), f"first fill should be ok, got {out!r}")
    out = cli("economy", "kx-101")
    check(0.0 in nums(out.replace("100km", "")), f"economy with one fill should be 0.0, got {out!r}")
    cli("fill", "kx-101", 20600, 48)
    cli("fill", "kx-101", 21000, 34)
    out = cli("economy", "KX-101")
    check(8.2 in nums(out.replace("100km", "")), f"economy should be 8.2, got {out!r}")
    out = cli("fill", "kx-101", 20900, 10)
    check(has(out, "error"), f"lower odometer should be an error, got {out!r}")
    out = cli("fill", "zz-999", 100, 10)
    check(has(out, "error"), f"unknown plate should be an error, got {out!r}")
    out = cli("economy", "kx-101")
    check(8.2 in nums(out.replace("100km", "")), f"rejected fills must not change economy, got {out!r}")


if __name__ == "__main__":
    main()
