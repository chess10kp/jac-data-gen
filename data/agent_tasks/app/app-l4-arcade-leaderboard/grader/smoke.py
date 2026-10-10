#!/usr/bin/env python3
"""Hidden HTTP smoke check. Usage: smoke.py <workspace_dir>

Copies the workspace to a fresh temp dir (fresh graph store), boots
`jac run --serve --port <free> main.jac` (the replacement for the removed
`jac start`), waits for /healthz, exercises the endpoints the request names
and asserts status + JSON shape. Last stdout line is a JSON verdict
{"start": bool, "behavioral": bool, "failures": [...]}; exit 0 iff both true.
Design-tolerant: a walker may report one list or one report per item, report
nodes or dicts, and expose ids as `id` or the wire `_jac_id`.
"""
import json, os, shutil, signal, socket, subprocess, sys, tempfile, time, urllib.error, urllib.request

BOOT_TIMEOUT = int(os.environ.get("SMOKE_BOOT_TIMEOUT", "300"))
FAIL: list = []


def check(cond, msg):
    if not cond:
        FAIL.append(msg)
    return bool(cond)


class Server:
    def __init__(self, ws):
        self.dir = tempfile.mkdtemp(prefix="smoke_")
        shutil.copytree(ws, self.dir, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns(".jac", "node_modules", "__pycache__"))
        s = socket.socket(); s.bind(("127.0.0.1", 0)); self.port = s.getsockname()[1]; s.close()
        if os.path.exists(os.path.join(self.dir, "jac.toml")) and os.environ.get("SMOKE_INSTALL", "1") == "1":
            toml = open(os.path.join(self.dir, "jac.toml")).read()
            if "[dependencies.npm]" in toml:  # web-app: client deps needed to bundle
                subprocess.run(["jac", "install"], cwd=self.dir, stdin=subprocess.DEVNULL, timeout=900)
        self.log = open(os.path.join(self.dir, "server.log"), "w")
        self.proc = subprocess.Popen(["jac", "run", "--serve", "--port", str(self.port), "main.jac"],
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

    def call(self, path, body=None, method="POST"):
        data = json.dumps(body or {}).encode() if method != "GET" else None
        req = urllib.request.Request(self.base + path, data=data, method=method,
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

    def get_raw(self, path):
        try:
            with urllib.request.urlopen(self.base + path, timeout=60) as r:
                return r.status, r.read().decode(errors="replace")
        except urllib.error.HTTPError as e:
            return e.code, ""
        except Exception:
            return 0, ""

    def close(self):
        try:
            os.killpg(self.proc.pid, signal.SIGTERM); self.proc.wait(15)
        except Exception:
            try:
                os.killpg(self.proc.pid, signal.SIGKILL)
            except Exception:
                pass
        self.log.close()
        sys.stderr.write("---- server.log tail ----\n" + "".join(open(os.path.join(self.dir, "server.log"), errors="replace").readlines()[-25:]))


def reports(env):
    return ((env or {}).get("data") or {}).get("reports") or []


def items(env):
    """List-valued answer: a function result list, one reported list, or one report per item."""
    r = reports(env)
    if not r:
        res = ((env or {}).get("data") or {}).get("result")
        return res if isinstance(res, list) else []
    if len(r) == 1 and isinstance(r[0], list):
        return r[0]
    if all(isinstance(x, list) for x in r):
        return [y for x in r for y in x]
    return r


def one(env):
    """Single-valued answer: first report, else the function `result`."""
    r = reports(env)
    if r:
        return r[0]
    return ((env or {}).get("data") or {}).get("result")


def is_error(status, env):
    if status >= 400 or not isinstance(env, dict) or env.get("ok") is False:
        return True
    x = one(env)
    return isinstance(x, dict) and bool(x.get("error"))


def ok_resp(status, env):
    return status == 200 and isinstance(env, dict) and env.get("ok") is True and not is_error(status, env)


def idof(x):
    if not isinstance(x, dict):
        return None
    return x.get("id") or x.get("_jac_id")


def num(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return None


def main():
    ws = sys.argv[1]
    srv = Server(ws)
    started = False
    try:
        started = srv.wait()
        check(started, "server did not answer /healthz")
        if started:
            try:
                checks(srv)
            except Exception as e:  # malformed responses count as failures
                FAIL.append(f"exception: {type(e).__name__}: {e}")
    finally:
        srv.close()
    verdict = {"start": started, "behavioral": started and not FAIL, "failures": FAIL[:20]}
    print(json.dumps(verdict))
    sys.exit(0 if verdict["start"] and verdict["behavioral"] else 1)


def board(srv, g, p, s):
    st, env = srv.call("/walker/submit_score", {"game": g, "player": p, "score": s})
    check(ok_resp(st, env), f"submit_score failed: {st} {env}")
    return [(e.get("player"), e.get("score")) for e in items(env) if isinstance(e, dict)]


def checks(srv):
    board(srv, "galaga", "alice", 300)
    board(srv, "galaga", "bob", 500)
    b = board(srv, "galaga", "cat", 100)
    check(b == [("BOB", 500), ("ALI", 300), ("CAT", 100)], f"board wrong: {b}")
    b = board(srv, "galaga", "Bob", 50)
    check(b == [("BOB", 500), ("ALI", 300), ("CAT", 100)], f"lower score should not change board: {b}")
    for p, s in [("dan", 400), ("eve", 200), ("fay", 250)]:
        b = board(srv, "galaga", p, s)
    check(b == [("BOB", 500), ("DAN", 400), ("ALI", 300), ("FAY", 250), ("EVE", 200)], f"top-5 wrong: {b}")
    b = board(srv, "digdug", "zed", 10)
    check(b == [("ZED", 10)], f"games should be separate: {b}")
    st, env = srv.call("/walker/submit_score", {"game": "galaga", "player": "neg", "score": -3})
    check(is_error(st, env), f"negative score should be an error: {st} {env}")


if __name__ == "__main__":
    main()
