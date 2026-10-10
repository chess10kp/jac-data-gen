#!/usr/bin/env python3
"""Trajectory-generation runner: a teacher model (default zai/glm-5.3-flash) solves
validated agent tasks inside the pinned pi-jac-ast-edit deploy harness
(vendor/pi-jac-ast-edit/deploy/jacpi.sh); every session is recorded, its final
workspace graded with grade.py, and the artifacts written under --out.

Subcommands
  prewarm  --shared DIR        unpack the jac runtime + fetch the embedded postgres
                               dist into a shared cache, by grading a few references
  probe    --shared DIR        under the session isolation, run a persistence task's
                               reference (sequential `jac run` steps) + `jac check`;
                               rc 0 iff it works (run before spending API calls)
  run      --shard I/N ...     run this shard's (task, sample) sessions

Isolation (per session; no state can leak between sessions or into the box):
  <root>/<sid>/ws/<project>   fresh copy of starter/ (the agent's cwd)
  <root>/<sid>/home           HOME, XDG_* (pi + ast-edit caches)
  <root>/<sid>/cache          JAC_CACHE_HOME: rt/ stage0/ toolchains/ symlinked to the
                              shared read-only pre-warmed cache (the unpacked runtime
                              is the slow part); jir/ copied; pg/ private (pg/dist
                              symlinked) so every session gets a clean embedded postgres
  <root>/<sid>/tmp            TMPDIR (postgres socket dirs etc.)
  <root>/<sid>/agent          pi agent dir: settings.json only (retry policy and a
                              shell prefix that unsets the API key for the bash tool)
With bubblewrap (--sandbox bwrap|auto): / read-only, the repo checkout and the
runner work dir hidden (tmpfs; graders live there), private /tmp, pid namespace,
writable binds only for <root>/<sid>; network stays on (the model API).

Outputs (under --out): sessions/<sid>.jsonl, workspaces/<sid>.tar.gz + .diff,
logs/<sid>.{out,err}, runs.jsonl, grades.jsonl, stats.json.
"""
from __future__ import annotations

import argparse
import difflib
import json
import os
import random
import re
import shutil
import signal
import subprocess
import sys
import tarfile
import tempfile
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
TASKS = REPO / "data" / "agent_tasks"
HARNESS = REPO / "vendor" / "pi-jac-ast-edit"
sys.path.insert(0, str(HERE))
import grade as grader  # noqa: E402

KEY_ENVS = ("ZAI_API_KEY", "ZAI_CODING_CN_API_KEY")
SKIP = grader.SKIP
RATE_RE = re.compile(r"\b429\b|rate.?limit|too many requests|quota|usage limit|concurrency", re.I)
SHARED_LINKS = ("rt", "stage0", "toolchains")
PI_SETTINGS = {
    "shellCommandPrefix": "unset " + " ".join(KEY_ENVS),
    "retry": {"enabled": True, "maxRetries": 6, "baseDelayMs": 5000,
              "provider": {"maxRetries": 0, "maxRetryDelayMs": 120000}},
}
PASS_ENV = ("PATH", "LANG", "LC_ALL", "SSL_CERT_FILE", "SSL_CERT_DIR", "NODE_EXTRA_CA_CERTS")


def log(msg: str) -> None:
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)


# --------------------------------------------------------------------------- tasks
def load_pairs(kinds: list[str], k: int, only: set[str] | None) -> list[tuple[Path, int]]:
    pairs = []
    for kind in kinds:
        for td in grader.validated_tasks(kind):
            if only and td.name not in only:
                continue
            pairs += [(td, s) for s in range(k)]
    return pairs


def project_name(task_id: str) -> str:
    """nat-l3-parking-garage -> parking-garage (the agent's cwd basename)."""
    return re.sub(r"^[a-z]+-l\d-", "", task_id) or task_id


# --------------------------------------------------------------------------- isolation
def which_bwrap() -> str | None:
    b = shutil.which("bwrap")
    if not b:
        return None
    p = subprocess.run([b, "--ro-bind", "/", "/", "--dev", "/dev", "--proc", "/proc", "--unshare-pid",
                        "true"], capture_output=True, text=True)
    return b if p.returncode == 0 else None


def make_cache(shared: Path, dst: Path) -> None:
    """Private JAC_CACHE_HOME that shares the expensive read-only parts of `shared`."""
    dst.mkdir(parents=True, exist_ok=True)
    for name in SHARED_LINKS:
        if (shared / name).exists():
            (dst / name).symlink_to(shared / name)
    if (shared / "jir").is_dir():
        shutil.copytree(shared / "jir", dst / "jir", symlinks=True)
    (dst / "pg").mkdir()
    if (shared / "pg" / "dist").is_dir():
        (dst / "pg" / "dist").symlink_to(shared / "pg" / "dist")
    (dst / "tmp").mkdir()


def session_env(sdir: Path, with_key: bool) -> dict:
    env = {k: os.environ[k] for k in PASS_ENV if k in os.environ}
    home = sdir / "home"
    env.update({
        "HOME": str(home), "USER": os.environ.get("USER", "runner"), "SHELL": "/bin/bash", "TERM": "dumb",
        "XDG_CACHE_HOME": str(home / ".cache"), "XDG_CONFIG_HOME": str(home / ".config"),
        "XDG_DATA_HOME": str(home / ".local/share"), "XDG_STATE_HOME": str(home / ".local/state"),
        "TMPDIR": str(sdir / "tmp"), "JAC_CACHE_HOME": str(sdir / "cache"),
        "JACPI_AGENT_DIR": str(sdir / "agent"), "JACPI_SOURCE_AGENT_DIR": str(sdir / "no-source-agent"),
        "JAC_AST_EDIT_CACHE_DIR": str(home / ".cache" / "pi-jac-ast-edit"),
        "PI_OFFLINE": "1", "PI_SKIP_VERSION_CHECK": "1", "PI_TELEMETRY": "0", "NO_COLOR": "1",
    })
    if with_key:
        for k in KEY_ENVS:
            if os.environ.get(k):
                env[k] = os.environ[k]
    return env


def make_session_dirs(sdir: Path, shared: Path) -> None:
    for d in ("home/.cache", "home/.config", "tmp", "agent", "session"):
        (sdir / d).mkdir(parents=True, exist_ok=True)
    make_cache(shared, sdir / "cache")
    (sdir / "agent" / "settings.json").write_text(json.dumps(PI_SETTINGS, indent=1))


def wrap(cmd: list[str], sdir: Path, cwd: Path, bwrap: str | None, extra_ro: list[Path]) -> list[str]:
    if not bwrap:
        return cmd
    w = [bwrap, "--ro-bind", "/", "/", "--dev", "/dev", "--proc", "/proc", "--tmpfs", "/tmp",
         "--unshare-pid", "--unshare-ipc", "--die-with-parent", "--new-session"]
    hide = {REPO}
    if os.environ.get("RUNNER_WORKSPACE"):          # /home/runner/work/<repo>: checkout + _temp step scripts
        hide.add(Path(os.environ["RUNNER_WORKSPACE"]).parent)
    for h in sorted(hide, key=lambda p: len(str(p))):
        if not str(sdir).startswith(str(h) + "/"):
            w += ["--tmpfs", str(h)]
    for p in extra_ro:
        w += ["--ro-bind", str(p), str(p)]
    w += ["--bind", str(sdir), str(sdir), "--chdir", str(cwd), "--"]
    return w + cmd


def reap(sdir: Path) -> int:
    """Kill leftovers (e.g. an embedded postgres) whose cmdline/cwd/env points into sdir."""
    n, me = 0, os.getpid()
    tag = str(sdir)
    for p in Path("/proc").iterdir():
        if not p.name.isdigit() or int(p.name) == me:
            continue
        try:
            cmd = (p / "cmdline").read_bytes().replace(b"\0", b" ").decode(errors="replace")
            cwd = os.readlink(p / "cwd") if (p / "cwd").exists() else ""
            envb = (p / "environ").read_bytes()
        except OSError:
            continue
        if tag in cmd or cwd.startswith(tag) or f"JAC_CACHE_HOME={tag}/".encode() in envb:
            try:
                os.kill(int(p.name), signal.SIGKILL)
                n += 1
            except OSError:
                pass
    return n


def run_cmd(cmd: list[str], cwd: Path, env: dict, timeout: float, stdout, stderr) -> tuple[int, bool, float]:
    t0 = time.time()
    p = subprocess.Popen(cmd, cwd=cwd, env=env, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr,
                         start_new_session=True)
    timed_out = False
    try:
        rc = p.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        timed_out = True
        try:
            os.killpg(p.pid, signal.SIGTERM)
            rc = p.wait(timeout=20)
        except Exception:
            try:
                os.killpg(p.pid, signal.SIGKILL)
            except OSError:
                pass
            rc = p.wait()
    return rc, timed_out, time.time() - t0


# --------------------------------------------------------------------------- session analysis
def session_summary(fp: Path | None) -> dict:
    s = {"n_tool_calls": 0, "n_responses": 0, "tools": {}, "api_errors": [], "rate_limit_events": 0,
         "final_stop": None, "final_error": None, "model": None, "has_snapshot": False, "tokens_total": 0}
    if not fp or not fp.exists():
        return s
    for line in fp.read_text(errors="replace").splitlines():
        try:
            r = json.loads(line)
        except ValueError:
            continue
        if r.get("type") == "custom" and r.get("customType") == "jac-harness-snapshot":
            s["has_snapshot"] = True
        if r.get("type") != "message" or r["message"].get("role") != "assistant":
            continue
        m = r["message"]
        s["model"] = m.get("model") or s["model"]
        s["final_stop"], s["final_error"] = m.get("stopReason"), m.get("errorMessage")
        if m.get("errorMessage"):
            em = str(m["errorMessage"])[:300]
            s["api_errors"].append(em)
            s["rate_limit_events"] += bool(RATE_RE.search(em))
            continue
        s["n_responses"] += 1
        s["tokens_total"] += int((m.get("usage") or {}).get("totalTokens") or 0)
        for b in m.get("content") or []:
            if b.get("type") == "toolCall":
                s["n_tool_calls"] += 1
                s["tools"][b["name"]] = s["tools"].get(b["name"], 0) + 1
    return s


def snapshot_ws(ws: Path, starter: Path, out_tar: Path, out_diff: Path) -> dict:
    def files(root: Path) -> dict[str, Path]:
        out = {}
        if root.is_dir():
            for p in root.rglob("*"):
                if p.is_file() and not set(p.relative_to(root).parts) & set(SKIP):
                    out[str(p.relative_to(root))] = p
        return out
    with tarfile.open(out_tar, "w:gz") as tf:
        for rel, p in sorted(files(ws).items()):
            tf.add(p, arcname=rel)
    a, b = files(starter), files(ws)
    chunks, changed = [], {"added": [], "removed": [], "modified": []}
    for rel in sorted(set(a) | set(b)):
        x = a[rel].read_text(errors="replace").splitlines(True) if rel in a else []
        y = b[rel].read_text(errors="replace").splitlines(True) if rel in b else []
        if x == y:
            continue
        changed["added" if rel not in a else "removed" if rel not in b else "modified"].append(rel)
        chunks += difflib.unified_diff(x, y, f"a/{rel}", f"b/{rel}")
    out_diff.write_text("".join(chunks))
    return changed


# --------------------------------------------------------------------------- runner
class Runner:
    def __init__(self, a):
        self.a = a
        self.out = Path(a.out).resolve()
        self.root = Path(a.root).resolve()
        self.shared = Path(a.shared).resolve()
        for d in ("sessions", "workspaces", "logs"):
            (self.out / d).mkdir(parents=True, exist_ok=True)
        self.lock = threading.Lock()
        self.pause_until = 0.0
        self.n_rl = 0
        self.bwrap = None if a.sandbox == "none" else which_bwrap()
        if a.sandbox == "bwrap" and not self.bwrap:
            raise SystemExit("--sandbox bwrap requested but bwrap is unusable")
        self.extra_ro = [HARNESS]

    def record(self, name: str, row: dict) -> None:
        with self.lock:
            with (self.out / name).open("a") as f:
                f.write(json.dumps(row) + "\n")

    def wait_backoff(self) -> None:
        while True:
            with self.lock:
                d = self.pause_until - time.time()
            if d <= 0:
                return
            time.sleep(min(d, 30))

    def rate_limited(self) -> float:
        with self.lock:
            self.n_rl += 1
            delay = min(900, 60 * 2 ** min(self.n_rl - 1, 4)) * (1 + random.random() * 0.25)
            self.pause_until = max(self.pause_until, time.time() + delay)
            return delay

    def attempt(self, td: Path, sample: int, n: int) -> tuple[dict, Path, Path]:
        meta = json.loads((td / "task.json").read_text())
        sid = f"{meta['id']}__s{sample}"
        sdir = self.root / f"{sid}.a{n}"
        if sdir.exists():
            shutil.rmtree(sdir, ignore_errors=True)
        make_session_dirs(sdir, self.shared)
        ws = sdir / "ws" / project_name(meta["id"])
        ws.mkdir(parents=True)
        grader.copy_ws(td / "starter", ws)
        request = (td / "request.md").read_text().strip()
        cmd = [str(HARNESS / "deploy" / "jacpi.sh"), "--model", self.a.model,
               "--session-dir", str(sdir / "session"), "-p", request]
        env = session_env(sdir, with_key=True)
        with open(self.out / "logs" / f"{sid}.out", "w") as so, open(self.out / "logs" / f"{sid}.err", "w") as se:
            rc, timed_out, wall = run_cmd(wrap(cmd, sdir, ws, self.bwrap, self.extra_ro), ws, env,
                                          self.a.timeout * 60, so, se)
        reaped = reap(sdir)
        sess = sorted((sdir / "session").glob("*.jsonl"))
        summ = session_summary(sess[-1] if sess else None)
        row = {"sid": sid, "task_id": meta["id"], "kind": meta["kind"], "level": meta["level"], "sample": sample,
               "attempt": n, "model": self.a.model, "rc": rc, "timed_out": timed_out, "wall_s": round(wall, 1),
               "reaped": reaped, "sandbox": "bwrap" if self.bwrap else "none", "n_session_files": len(sess),
               **summ}
        return row, sdir, ws

    def one(self, td: Path, sample: int) -> dict:
        row = None
        for n in range(self.a.max_attempts):
            self.wait_backoff()
            row, sdir, ws = self.attempt(td, sample, n)
            api_fail = row["final_stop"] in ("error", "aborted") and not row["timed_out"]
            no_session = row["n_session_files"] == 0
            if (api_fail or no_session) and n + 1 < self.a.max_attempts:
                rl = bool(RATE_RE.search(str(row["final_error"] or ""))) or row["rate_limit_events"] > 0
                delay = self.rate_limited() if rl else 20
                log(f"{row['sid']} attempt {n} API failure (rate_limited={rl}, {row['final_error']!r:.120}); "
                    f"retry after {delay:.0f}s")
                self.record("rate_limits.jsonl", {"sid": row["sid"], "attempt": n, "rate_limited": rl,
                                                  "error": str(row["final_error"])[:300], "time": time.time()})
                self.save(row, sdir, ws, td, final=False)
                shutil.rmtree(sdir, ignore_errors=True)
                continue
            break
        self.save(row, sdir, ws, td, final=True)
        shutil.rmtree(sdir, ignore_errors=True)
        return row

    def save(self, row: dict, sdir: Path, ws: Path, td: Path, final: bool) -> None:
        sid = row["sid"] if final else f"{row['sid']}.failed{row['attempt']}"
        sess = sorted((sdir / "session").glob("*.jsonl"))
        if sess:
            shutil.copy(sess[-1], self.out / "sessions" / f"{sid}.jsonl")
        if not final:
            self.record("runs_failed.jsonl", row)
            return
        row["changed"] = snapshot_ws(ws, td / "starter", self.out / "workspaces" / f"{sid}.tar.gz",
                                     self.out / "workspaces" / f"{sid}.diff")
        g = self.grade(td, ws, sdir)
        row["passed"] = g["passed"]
        self.record("runs.jsonl", row)
        self.record("grades.jsonl", {"sid": sid, **g})
        log(f"DONE {sid} rc={row['rc']} timeout={row['timed_out']} calls={row['n_tool_calls']} "
            f"wall={row['wall_s']}s passed={g['passed']} failed={g['failed_gates']}")

    def grade(self, td: Path, ws: Path, sdir: Path) -> dict:
        gdir = sdir / "grade"
        gdir.mkdir()
        (gdir / "tmp").mkdir()
        make_cache(self.shared, gdir / "cache")
        env = {**session_env(gdir, with_key=False), "HOME": str(gdir), "JAC_CACHE_HOME": str(gdir / "cache"),
               "TMPDIR": str(gdir / "tmp")}
        try:
            p = subprocess.run([sys.executable, str(HERE / "grade.py"), str(td), str(ws), "--json"], env=env,
                               cwd=gdir, capture_output=True, text=True, timeout=self.a.grade_timeout * 60,
                               start_new_session=True)
            line = next((ln for ln in reversed(p.stdout.splitlines()) if ln.startswith("{")), None)
            g = json.loads(line) if line else {"passed": False, "gates": {}, "failed_gates": ["grader"],
                                               "detail": (p.stderr or p.stdout)[-800:]}
        except subprocess.TimeoutExpired:
            g = {"passed": False, "gates": {}, "failed_gates": ["grader_timeout"], "detail": "grader timeout"}
        reap(gdir)
        return g


def stats(out: Path) -> dict:
    runs = [json.loads(x) for x in (out / "runs.jsonl").read_text().splitlines()] if (out / "runs.jsonl").exists() else []
    rl = (out / "rate_limits.jsonl").read_text().splitlines() if (out / "rate_limits.jsonl").exists() else []
    n = len(runs)
    return {"sessions": n, "passed": sum(r.get("passed", False) for r in runs),
            "timed_out": sum(r["timed_out"] for r in runs),
            "api_error_final": sum(r["final_stop"] in ("error", "aborted") for r in runs),
            "rate_limit_retries": len(rl), "rate_limit_events_in_sessions": sum(r["rate_limit_events"] for r in runs),
            "tool_calls_mean": round(sum(r["n_tool_calls"] for r in runs) / max(1, n), 1),
            "wall_s_mean": round(sum(r["wall_s"] for r in runs) / max(1, n), 1),
            "sandbox": sorted({r["sandbox"] for r in runs})}


def key_scan(out: Path) -> list[str]:
    """Files under out holding an API key value -> deleted; returns their paths."""
    keys = [os.environ[k].encode() for k in KEY_ENVS if len(os.environ.get(k, "")) >= 8]
    hits = []
    if not keys:
        return hits
    for p in out.rglob("*"):
        if not p.is_file():
            continue
        data = p.read_bytes()
        if p.suffix == ".gz":
            try:
                import gzip
                data += gzip.decompress(data)
            except Exception:
                pass
        if any(k in data for k in keys):
            hits.append(str(p.relative_to(out)))
            p.unlink()
    return hits


# --------------------------------------------------------------------------- prewarm / probe
def pick_persistence_task() -> Path | None:
    for td in grader.validated_tasks("native"):
        g = td / "grader" / "gate.json"
        if g.exists() and json.loads(g.read_text()).get("run_steps") and (td / "starter" / "jac.toml").exists():
            return td
    return None


def cmd_prewarm(a) -> int:
    shared = Path(a.shared).resolve()
    shared.mkdir(parents=True, exist_ok=True)
    env = {**os.environ, "JAC_CACHE_HOME": str(shared)}
    for k in KEY_ENVS:
        env.pop(k, None)
    t0 = time.time()
    subprocess.run(["jac", "--version"], env=env, check=True)
    subprocess.run(["jac", "guide"], env=env, capture_output=True)
    picks = [pick_persistence_task()] + grader.validated_tasks("app")[10:11] + grader.validated_tasks("native")[:1]
    rc = 0
    for td in [p for p in picks if p]:
        with tempfile.TemporaryDirectory() as tmp:
            ref = grader.reference_ws(td, Path(tmp) / "ref")
            p = subprocess.run([sys.executable, str(HERE / "grade.py"), str(td), str(ref), "--json"], env=env,
                               capture_output=True, text=True, cwd=tmp)
            g = json.loads(p.stdout.splitlines()[-1]) if p.stdout.strip() else {"passed": False, "detail": p.stderr[-500:]}
            log(f"prewarm {td.name}: ref passed={g['passed']} {g.get('detail', '')[:300]}")
            rc |= not g["passed"]
    sizes = {d.name: subprocess.run(["du", "-sh", str(d)], capture_output=True, text=True).stdout.split()[0]
             for d in shared.iterdir() if d.is_dir()}
    log(f"prewarm done in {time.time() - t0:.0f}s; shared cache {sizes}")
    return rc


def cmd_probe(a) -> int:
    """Under session isolation: `jac check` + the run_steps of a persistence task's reference."""
    shared, root = Path(a.shared).resolve(), Path(a.root).resolve()
    bw = None if a.sandbox == "none" else which_bwrap()
    if a.sandbox == "bwrap" and not bw:
        log("PROBE bwrap requested but unusable")
        return 1
    td = pick_persistence_task()
    gate = json.loads((td / "grader" / "gate.json").read_text())
    sdir = root / "probe"
    shutil.rmtree(sdir, ignore_errors=True)
    make_session_dirs(sdir, shared)
    ws = sdir / "ws" / project_name(td.name)
    ws.mkdir(parents=True)
    grader.copy_ws(td / "grader" / "reference", ws)
    for p in (td / "grader" / "probes").iterdir():
        shutil.copy(p, ws / p.name)
    env = session_env(sdir, with_key=False)
    steps = [["jac", "check", *json.loads((td / "task.json").read_text())["target_paths"]]]
    steps += [["jac", "run", s["file"], *s.get("args", [])] for s in gate["run_steps"]]
    expects = [[]] + [s.get("expect", []) for s in gate["run_steps"]]
    # Isolation checks: the repo (graders) must be invisible and / read-only under bwrap.
    steps += [["bash", "-c", f"test ! -e {TASKS}/native && ! touch /usr/probe_w 2>/dev/null && echo ISOLATED"]] if bw else []
    expects += [["ISOLATED"]] if bw else []
    ok = True
    log(f"PROBE task={td.name} sandbox={'bwrap' if bw else 'none'}")
    for cmd, exp in zip(steps, expects):
        with tempfile.TemporaryFile("w+") as f:
            rc, to, wall = run_cmd(wrap(cmd, sdir, ws, bw, [HARNESS]), ws, env, 600, f, subprocess.STDOUT)
            f.seek(0)
            out = f.read()
        good = rc == 0 and all(e in out for e in exp)
        ok &= good
        log(f"PROBE {'ok ' if good else 'BAD'} {' '.join(cmd)[:80]} rc={rc} {wall:.1f}s" + ("" if good else f"\n{out[-1500:]}"))
    # the private cache really got its own postgres datadir, the shared one none
    pg_private = any((sdir / "cache" / "pg").glob("main*"))
    pg_shared = any((shared / "pg").glob("main*"))
    log(f"PROBE private pg datadir={pg_private} shared pg datadir={pg_shared} reaped={reap(sdir)}")
    shutil.rmtree(sdir, ignore_errors=True)
    log(f"PROBE {'PASS' if ok else 'FAIL'}")
    return 0 if ok else 1


def cmd_run(a) -> int:
    i, n = (int(x) for x in a.shard.split("/"))
    only = set(a.only.split(",")) if a.only else None
    pairs = load_pairs(a.kinds.split(","), a.k, only)
    mine = pairs[i::n]
    if a.limit:
        mine = mine[: a.limit]
    r = Runner(a)
    log(f"shard {i}/{n}: {len(mine)} of {len(pairs)} sessions; model={a.model} conc={a.concurrency} "
        f"timeout={a.timeout}m sandbox={'bwrap' if r.bwrap else 'none'}")
    with ThreadPoolExecutor(max_workers=a.concurrency) as ex:
        futs = []
        for j, (td, s) in enumerate(mine):
            futs.append(ex.submit(r.one, td, s))
            if j < a.concurrency:
                time.sleep(a.stagger)          # don't open all connections at the same instant
        for f in futs:
            try:
                f.result()
            except Exception as e:
                log(f"session crashed: {type(e).__name__}: {e}")
    st = stats(r.out)
    leaks = key_scan(r.out)
    st["key_leak_files"] = leaks
    (r.out / "stats.json").write_text(json.dumps(st, indent=1))
    log(f"STATS {json.dumps(st)}")
    if leaks:
        log(f"API KEY FOUND in {len(leaks)} output files; deleted them; failing shard")
        return 3
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in ("prewarm", "probe", "run"):
        p = sub.add_parser(name)
        p.add_argument("--shared", default=str(Path.home() / "traj_shared_cache"))
        p.add_argument("--root", default=str(Path.home() / "traj_sessions"))
        p.add_argument("--sandbox", choices=["auto", "bwrap", "none"], default="auto")
    rp = sub.choices["run"]
    rp.add_argument("--shard", default="0/1")
    rp.add_argument("--out", default="ci_out")
    rp.add_argument("--kinds", default="native,app")
    rp.add_argument("--k", type=int, default=2, help="samples per task")
    rp.add_argument("--only", help="comma list of task ids")
    rp.add_argument("--limit", type=int, default=0, help="max sessions this shard")
    rp.add_argument("--model", default="zai/glm-5.3-flash")
    rp.add_argument("--timeout", type=float, default=20, help="wall minutes per session")
    rp.add_argument("--grade-timeout", type=float, default=30, help="minutes per grade")
    rp.add_argument("--concurrency", type=int, default=3)
    rp.add_argument("--max-attempts", type=int, default=3)
    rp.add_argument("--stagger", type=float, default=5)
    a = ap.parse_args()
    return {"prewarm": cmd_prewarm, "probe": cmd_probe, "run": cmd_run}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
