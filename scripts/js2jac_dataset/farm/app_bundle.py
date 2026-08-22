#!/usr/bin/env python3
"""Whole-FARM-app bundler: collect a repo's model + handler + db + auth files.

Extends farm_discover (which grabs only models/*.py) toward the HANDLER-TRANSLATION
framing: the richer, app-representative training signal (real query patterns,
partial updates, auth guards, response envelopes) lives in routes/ + database/, not
in the schema. This bundles those sibling files per repo so a future
handler-translation prep can feed composer the ACTUAL FastAPI+Beanie logic.

Classifies each .py file by role from its path/content:
  model    -> defines Beanie/ODMantic Document/Model classes   (lifts to node/edge)
  db       -> the query layer (`.find`/`.get`/`.create`/`.delete`/`.update`)
  route    -> FastAPI router (`APIRouter`, `@router`/`@app` decorators)
  auth     -> auth guards (`HTTPBearer`, `jwt`, `Depends`, OAuth2)
  schema   -> pydantic request/response DTOs (BaseModel, not Document)

Input:  a local repo dir (already cloned) OR --repo owner/name (shallow-cloned).
Output: one bundle row -> {repo, files:{role:[{path,source}]}, nodes:[...]}

Usage:
  ./farm_app_bundle.py --dir /path/to/cloned/repo --out farm_apps.jsonl
  ./farm_app_bundle.py --repo Youngestdev/fastapi-mongo --out farm_apps.jsonl
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "converters"))
import mongo_odm_to_jac as odm

MAX_FILE = 60_000

_RX = {
    "model":  re.compile(r"\b(Document|EmbeddedDocument)\b|\bodmantic\b.*\bModel\b"),
    "db":     re.compile(r"\.(find|find_one|get|create|insert|delete|save|update|all)\s*\(|motor|AsyncIOMotorClient"),
    "route":  re.compile(r"APIRouter|@\w+\.(get|post|put|patch|delete)\b|include_router"),
    "auth":   re.compile(r"HTTPBearer|OAuth2|jwt|Depends\s*\(|verify_password|HTTPAuthorizationCredentials"),
    "schema": re.compile(r"\bBaseModel\b"),
}


def classify(path: str, src: str) -> str | None:
    """Assign one role; precedence model > route > db > auth > schema.

    Route is checked before db because FastAPI decorators (`@router.get(...)`)
    contain `.get(`, which the db regex would otherwise claim.
    """
    p = path.lower()
    if _RX["model"].search(src):
        return "model"
    if _RX["route"].search(src) or "/routes/" in p or "/routers/" in p:
        return "route"
    if _RX["db"].search(src) or "database" in p or "crud" in p:
        return "db"
    if _RX["auth"].search(src) or "/auth/" in p:
        return "auth"
    if _RX["schema"].search(src) or "/schemas/" in p:
        return "schema"
    return None


def collect(repo_dir: Path) -> dict:
    files: dict[str, list] = {r: [] for r in ("model", "db", "route", "auth", "schema")}
    nodes: list[str] = []
    for f in sorted(repo_dir.rglob("*.py")):
        if any(part in (".git", "tests", "test", "__pycache__", "migrations", "alembic")
               for part in f.parts):
            continue
        try:
            src = f.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        if len(src) > MAX_FILE:
            continue
        role = classify(str(f), src)
        if role is None:
            continue
        rel = str(f.relative_to(repo_dir))
        files[role].append({"path": rel, "source": src})
        if role == "model":
            try:
                _arch, specs = odm.analyze(src)
                nodes += [s["node"] for s in specs if s["scalar_fields"] and s["tag_field"]]
            except SyntaxError:
                pass
    return {"files": files, "nodes": sorted(set(nodes))}


def clone(repo: str) -> Path:
    d = Path(tempfile.mkdtemp(prefix="farm_app_"))
    subprocess.run(["git", "clone", "--depth", "1",
                    f"https://github.com/{repo}", str(d)],
                   capture_output=True, text=True, timeout=180)
    return d


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir")
    ap.add_argument("--repo")
    ap.add_argument("--repos-from", help="jsonl with a 'repo' field per line (e.g. farm_models.jsonl); bundle each unique repo")
    ap.add_argument("--out", required=True)
    ap.add_argument("--limit", type=int, default=0, help="max repos for --repos-from")
    args = ap.parse_args()

    # jobs: (local_dir_or_None, repo_name). A None dir means clone-on-demand.
    jobs: list[tuple[str | None, str]] = []
    if args.dir:
        jobs.append((args.dir, args.dir))
    elif args.repo:
        jobs.append((None, args.repo))
    elif args.repos_from:
        seen = []
        for ln in Path(args.repos_from).read_text().splitlines():
            if not ln.strip():
                continue
            r = json.loads(ln).get("repo")
            if r and r not in seen:
                seen.append(r)
        if args.limit:
            seen = seen[:args.limit]
        done = set()
        if Path(args.out).exists():
            for ln in Path(args.out).read_text().splitlines():
                if ln.strip():
                    done.add(json.loads(ln).get("repo"))
        jobs = [(None, r) for r in seen if r not in done]
    else:
        print("need --dir, --repo, or --repos-from", file=sys.stderr); return 2

    import shutil
    with open(args.out, "a", encoding="utf-8") as fh:
        for local, repo_name in jobs:
            repo_dir = Path(local) if local else clone(repo_name)   # lazy clone
            try:
                bundle = collect(repo_dir)
            except Exception as e:  # noqa: BLE001
                print(f"[bundle] {repo_name}: FAILED ({e})"); continue
            finally:
                if local is None:
                    shutil.rmtree(repo_dir, ignore_errors=True)
            bundle["repo"] = repo_name
            fh.write(json.dumps(bundle) + "\n"); fh.flush()
            counts = {r: len(v) for r, v in bundle["files"].items()}
            print(f"[bundle] {repo_name}: {counts}  nodes={bundle['nodes']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
