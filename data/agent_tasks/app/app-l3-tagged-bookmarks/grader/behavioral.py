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
    cli("save", "https://jac-lang.org", "Jac", "lang,Docs")
    cli("save", "https://example.com/recipes", "Recipes", "food")
    cli("save", "https://docs.python.org", "Python", "lang,docs, reference")
    out = cli("find", "lang")
    lines = [l.strip() for l in out.splitlines() if l.strip().startswith("http")]
    check(lines == ["https://docs.python.org", "https://jac-lang.org"], f"find lang should list 2 urls sorted, got {out!r}")
    cli("save", "https://jac-lang.org", "Jac language", "osp")
    out = cli("find", "OSP")
    check(has(out, "https://jac-lang.org"), f"resave should add osp tag, got {out!r}")
    out = cli("find", "docs")
    check(has(out, "https://jac-lang.org"), f"resave must not drop old tags, got {out!r}")
    out = cli("tags")
    pairs = dict(l.split()[:2] for l in out.splitlines() if len(l.split()) == 2)
    check(pairs.get("docs") == "2" and pairs.get("lang") == "2" and pairs.get("food") == "1"
          and pairs.get("reference") == "1" and pairs.get("osp") == "1", f"tag counts wrong: {out!r}")
    out = cli("delete", "https://example.com/recipes")
    check(has(out, "deleted"), f"delete should print deleted, got {out!r}")
    out = cli("tags")
    check(not has(out, "food"), f"orphan tag food should disappear, got {out!r}")
    out = cli("find", "food")
    check(has(out, "no bookmarks"), f"find food should print no bookmarks, got {out!r}")
    out = cli("delete", "https://nope.example")
    check(has(out, "not found"), f"deleting unknown url should print not found, got {out!r}")


if __name__ == "__main__":
    main()
