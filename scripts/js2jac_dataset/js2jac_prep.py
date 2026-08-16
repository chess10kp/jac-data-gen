#!/usr/bin/env python3
"""Stage 1 (prep) for the js2jac LLM-cleanup pipeline — analog of
agent_idiomize_prep.py in the py2jac composer flow.

Clones a slice of candidate repos, runs the js2jac project converter in
fail-open mode KEEPING the emitted Jac, and pairs every source file with its
outcome into one per-file record the composer stage can batch:

    {id, repo, commit, spdx, path, status, source_js, floor_jac|null}

- status=convertible -> floor_jac is the converter's emitted Jac; job = idiomize
- status=reject      -> floor_jac is null; job = strip/rewrite to convertible
                        (or reject) per strip_policy.json

inventory/skip files are dropped (not dataset material). Unlike harvest.py this
does NOT delete the clone until its records are written, and it retains the
emitted .jac in the work dir.

Usage:
  python3 js2jac_prep.py --candidates source/candidates.jsonl \
      --offset 0 --limit 40 --work-dir work --profile react
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "source"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import harvest  # noqa: E402  (clone/convert/profile_gate/pick_project_root/sh)
import profiles  # noqa: E402
import prisma_to_jac  # noqa: E402  (deterministic schema.prisma -> node/edge archetypes)

# Cap embedded source so a giant file can't blow the composer context. The
# cleanup pass targets component-sized files; anything larger is out of scope.
MAX_SRC_BYTES = 8000

# A file is ORM-backed (its DB calls should be rewritten against the lifted graph
# schema, not stripped to a hollow stub) if it touches the Prisma client.
_ORM_MARKERS = ("@prisma/client", "PrismaClient", "prisma.", "prismadb")


def lift_repo_schema(clone: Path) -> tuple[str | None, str | None]:
    """Find a schema.prisma anywhere in the clone and lift it once, deterministically.

    Returns (archetypes_jac, traversal_digest) or (None, None) if there is no schema
    or it fails to lift. One lift amortizes across every ORM file in the repo.
    """
    schemas = list(clone.rglob("schema.prisma"))
    if not schemas:
        return None, None
    try:
        text = schemas[0].read_text(errors="replace")
        archetypes, digest = prisma_to_jac.convert(text, keep_external_id=False)
        return (archetypes or None), (digest or None)
    except Exception:
        return None, None


def _is_orm_file(source_js: str) -> bool:
    return any(m in source_js for m in _ORM_MARKERS)


def rec_id(repo: str, path: str) -> str:
    return f"{repo.replace('/', '__')}::{path}"


def prep_repo(c: dict, profile: dict, workdir: Path, keep_out: Path) -> list[dict]:
    name = c["full_name"]
    cdir = workdir / name.replace("/", "__")
    recs: list[dict] = []
    try:
        if not harvest.clone(c["clone_url"], c.get("default_branch", "main"), cdir):
            return []
        ok, _why = harvest.profile_gate(cdir, profile)
        if not ok:
            return []
        commit = harvest.head_sha(cdir)
        # One deterministic schema-lift per repo (amortizes over every ORM file).
        schema_jac, schema_digest = lift_repo_schema(cdir)
        root = harvest.pick_project_root(cdir)
        out = keep_out / cdir.name
        rep_path = keep_out / (cdir.name + "__report.json")
        rep = harvest.convert(root, out, rep_path, fail_open=True)
        for f in rep.get("files", []):
            if f.get("kind") != "source":
                continue
            status = f.get("status")
            if status not in ("convertible", "reject"):
                continue  # drop inventory/skip
            spath = f.get("sourcePath", "")
            if profiles.path_excluded(spath, profile):
                continue  # vendored boilerplate (shadcn ui/*) — low value
            src_file = root / spath
            if not src_file.exists() or src_file.stat().st_size > MAX_SRC_BYTES:
                continue
            source_js = src_file.read_text(errors="replace")
            floor_jac = None
            floor_mode = "none"
            if status == "convertible" and f.get("jacPath"):
                jf = out / f["jacPath"]
                if jf.exists():
                    floor_jac = jf.read_text(errors="replace")
                    floor_mode = "full"
            elif status == "reject":
                # Project mode discarded any partial floor (cross-file/type-check
                # reject). Recover it standalone with holes: if >=1 declaration
                # converts, hand the composer a scaffold+holes instead of nothing,
                # so it patches rather than freestyles. Pure-fail files (kept 0)
                # stay floor=None — there is genuinely nothing to anchor.
                hc = harvest.hole_convert(source_js, spath)
                if hc.get("ok") and hc.get("keptCount", 0) >= 1:
                    floor_jac = hc.get("jac") or None
                    if floor_jac:
                        floor_mode = "holes"
            # ORM-backed files get the repo's lifted graph schema so the composer
            # rewrites `prisma.x.find/create/update` into walkers/traversals over
            # real nodes+edges instead of stripping to a hollow `return []`.
            orm = schema_jac is not None and _is_orm_file(source_js)
            # Transliteration trap: a floor that still CARRIES `prisma.` calls makes
            # the model idiomize that (keeping the dead prisma call) instead of
            # rewriting against the graph schema (observed on move.it). For ORM
            # files, drop such a floor so the schema is the sole anchor.
            if orm and floor_jac and "prisma" in floor_jac.lower():
                floor_jac, floor_mode = None, "none"
            recs.append({
                "id": rec_id(name, spath),
                "repo": name, "commit": commit, "spdx": c.get("spdx"),
                "path": spath, "status": status,
                "source_js": source_js, "floor_jac": floor_jac,
                "floor_mode": floor_mode,
                "orm": "prisma" if orm else None,
                "schema_jac": schema_jac if orm else None,
                "schema_digest": schema_digest if orm else None,
            })
        return recs
    finally:
        if cdir.exists():
            shutil.rmtree(cdir, ignore_errors=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--candidates", required=True)
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--limit", type=int, default=40)
    ap.add_argument("--work-dir", required=True)
    ap.add_argument("--profile", default="react")
    args = ap.parse_args()

    profile = profiles.get_profile(args.profile)
    cands = [json.loads(l) for l in Path(args.candidates).read_text().splitlines() if l.strip()]
    cands = cands[args.offset: args.offset + args.limit]

    # Absolute: harvest.convert shells out to `jac` with cwd=JAC_REPO, so any
    # relative derived path (keep_out/out/report) would resolve against the jac
    # repo and the report read-back would miss -> 0 files for every repo.
    work = Path(args.work_dir).resolve(); work.mkdir(parents=True, exist_ok=True)
    keep_out = work / "_emitted"; keep_out.mkdir(exist_ok=True)
    clones = Path(tempfile.mkdtemp(prefix="js2jac_prep_"))

    total = 0
    try:
        for i, c in enumerate(cands):
            recs = prep_repo(c, profile, clones, keep_out)
            for r in recs:
                (work / (r["id"].replace("/", "__").replace("::", "__") + ".json")).write_text(
                    json.dumps(r))
            total += len(recs)
            print(f"[{i}] {c['full_name']}: {len(recs)} files "
                  f"({sum(1 for r in recs if r['status']=='convertible')} conv / "
                  f"{sum(1 for r in recs if r['status']=='reject')} reject)", file=sys.stderr)
    finally:
        shutil.rmtree(clones, ignore_errors=True)
    print(f"prepped {total} per-file records -> {work}", file=sys.stderr)
    return 0 if total else 3  # rc=3 => end of slice (mirror composer_chunk contract)


if __name__ == "__main__":
    raise SystemExit(main())
