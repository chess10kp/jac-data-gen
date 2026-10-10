"""Shared HTTP smoke harness for `convert` L5 tasks (copied next to each grader/smoke.py).

A task's smoke.py defines `checks(srv)` and calls `run(checks)`. The harness copies
the workspace to a fresh temp dir (fresh graph store namespace), boots
`jac run --serve --port <free> main.jac`, waits for /healthz, runs the checks and
prints a JSON verdict {"start", "behavioral", "failures"} as the LAST stdout line;
exit 0 iff both are true. Walker endpoints are POST /walker/<name>.
"""
import json
import os
import shutil
import signal
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

BOOT_TIMEOUT = int(os.environ.get("SMOKE_BOOT_TIMEOUT", "300"))
FAIL: list = []


def check(cond, msg):
    if not cond:
        FAIL.append(msg)
    return bool(cond)


class Server:
    def __init__(self, ws, entry="main.jac"):
        self.dir = tempfile.mkdtemp(prefix="cvt_smoke_")
        shutil.copytree(ws, self.dir, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns(".jac", "node_modules", "__pycache__", "python"))
        s = socket.socket()
        s.bind(("127.0.0.1", 0))
        self.port = s.getsockname()[1]
        s.close()
        self.log = open(os.path.join(self.dir, "server.log"), "w")
        self.proc = subprocess.Popen(["jac", "run", "--serve", "--port", str(self.port), entry],
                                     cwd=self.dir, stdin=subprocess.DEVNULL, stdout=self.log,
                                     stderr=subprocess.STDOUT, start_new_session=True)
        self.base = f"http://127.0.0.1:{self.port}"

    def wait(self):
        t = time.time()
        while time.time() - t < BOOT_TIMEOUT:
            if self.proc.poll() is not None:
                return False
            try:
                with urllib.request.urlopen(self.base + "/healthz", timeout=3) as r:
                    if r.status == 200:
                        return True
            except Exception:
                time.sleep(1)
        return False

    def call(self, path, body=None):
        req = urllib.request.Request(self.base + path, data=json.dumps(body or {}).encode(), method="POST",
                                     headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                status, raw = r.status, r.read()
        except urllib.error.HTTPError as e:
            status, raw = e.code, e.read()
        except Exception as e:
            return 0, {"ok": False, "error": str(e)}
        try:
            return status, json.loads(raw)
        except ValueError:
            return status, {"_raw": raw.decode(errors="replace")[:500]}

    def walker(self, _endpoint, /, **body):
        """POST /walker/<endpoint>; returns (status, envelope, first report or None)."""
        st, env = self.call(f"/walker/{_endpoint}", body)
        return st, env, one(env)

    def close(self):
        try:
            os.killpg(self.proc.pid, signal.SIGTERM)
            self.proc.wait(15)
        except Exception:
            try:
                os.killpg(self.proc.pid, signal.SIGKILL)
            except Exception:
                pass
        self.log.close()
        sys.stderr.write("---- server.log tail ----\n" + "".join(
            open(os.path.join(self.dir, "server.log"), errors="replace").readlines()[-25:]))


def reports(env):
    return ((env or {}).get("data") or {}).get("reports") or []


def one(env):
    r = reports(env)
    return r[0] if r else None


def items(env):
    """List-valued answer: one reported list, or one report per item."""
    r = reports(env)
    if len(r) == 1 and isinstance(r[0], list):
        return r[0]
    if r and all(isinstance(x, list) for x in r):
        return [y for x in r for y in x]
    return r


def is_error(status, env):
    if status >= 400 or not isinstance(env, dict) or env.get("ok") is False:
        return True
    x = one(env)
    return isinstance(x, dict) and bool(x.get("error"))


def ok_resp(status, env):
    return status == 200 and isinstance(env, dict) and env.get("ok") is True and not is_error(status, env)


def run(checks, entry="main.jac"):
    ws = sys.argv[1]
    srv = Server(ws, entry)
    started = False
    try:
        started = srv.wait()
        check(started, "server did not answer /healthz")
        if started:
            try:
                checks(srv)
            except Exception as e:
                FAIL.append(f"exception: {type(e).__name__}: {e}")
    finally:
        srv.close()
    verdict = {"start": started, "behavioral": started and not FAIL, "failures": FAIL[:20]}
    print(json.dumps(verdict))
    sys.exit(0 if verdict["start"] and verdict["behavioral"] else 1)
