#!/usr/bin/env python3
"""Re-guard floor records against their stored idiomize candidates.

Context: the guard's 120s subprocess timeout turned a wedged jac toolchain
(corrupted embedded-Postgres codespace) into silent candidate rejections ->
floor fallback, contaminating recent `source: floor` entries (all of
chunk_17000, late chunk_15000 sub-batches, ...). This re-runs guard_one on
every floor record that still has a candidate, under the healed toolchain and
the raised JAC_PROC_TIMEOUT (env, default 300s).

Semantics identical to the stock guard (guard_one from agent_idiomize_guard:
jac check -> hidden tests -> keep-or-floor). Only records that FLIP to
idiomatic are rewritten in the master; everything else is byte-preserved.

Parallelism: each jac test round-trips embedded Postgres. Workers in one process
share ONE PG via --shared-tmp (fast after initdb). Run multiple shards with
disjoint shared-tmp dirs to scale past PG lock contention:

  scripts/reguard_floors_parallel.sh 4 4   # 4 shards × 4 workers

Checkpoints are append-only per shard (resume-safe). Merge after all shards:

  .venv/bin/python scripts/reguard_floors.py --merge

Outputs:
  - data/composer_dataset.jsonl            (atomically replaced, .bak.<ts> kept)
  - data/reguard_floors_changelog.jsonl    (one line per flipped record)
  - data/reguard_checkpoints/shard_<i>.jsonl (per-shard progress)
  - stdout progress log

Usage:
  JAC_PROC_TIMEOUT=300 .venv/bin/python scripts/reguard_floors.py --workers 8
  .venv/bin/python scripts/reguard_floors.py --shard 0 --shards 4 --workers 4
  .venv/bin/python scripts/reguard_floors.py --merge
"""
from __future__ import annotations
import argparse, glob, json, os, shutil, sys, tempfile, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

sys.path.insert(0, str(Path(__file__).resolve().parent))
from agent_idiomize_guard import guard_one  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
MASTER = ROOT / "data/composer_dataset.jsonl"
CKPT_DIR = ROOT / "data/reguard_checkpoints"


def load_candidates() -> dict[int, str | None]:
    cand: dict[int, str | None] = {}
    for f in sorted(glob.glob(str(ROOT / "data/chunks/*/candidates.jsonl"))):
        for line in Path(f).read_text().splitlines():
            if not line.strip():
                continue
            try:
                d = json.loads(line)
            except json.JSONDecodeError:
                continue
            cand.setdefault(d["id"], d.get("candidate"))
    return cand


def load_work() -> dict[int, dict]:
    work: dict[int, dict] = {}
    for p in glob.glob(str(ROOT / "data/chunks/*/work/*.json")):
        try:
            w = json.loads(Path(p).read_text())
        except (json.JSONDecodeError, ValueError):
            continue
        if isinstance(w, dict) and "id" in w:
            work.setdefault(w["id"], w)
    return work


def load_checkpoint(path: Path) -> dict[int, dict]:
    done: dict[int, dict] = {}
    if path.exists():
        for line in path.read_text().splitlines():
            if line.strip():
                d = json.loads(line)
                done[d["id"]] = d
    return done


def append_checkpoint(path: Path, res: dict) -> None:
    with open(path, "a") as f:
        f.write(json.dumps(res) + "\n")


def build_targets(rows: list[dict], cand: dict, work: dict, limit: int) -> list[dict]:
    targets = [r for r in rows
               if r.get("source") == "floor"
               and r["id"] in cand and cand[r["id"]]
               and r["id"] in work]
    if limit:
        targets = targets[:limit]
    return targets


def shard_targets(targets: list[dict], shard: int, shards: int) -> list[dict]:
    return [t for i, t in enumerate(targets) if i % shards == shard]


def run_shard(args: argparse.Namespace, targets: list[dict],
              cand: dict, work: dict, ckpt_path: Path) -> dict[int, dict]:
    done = load_checkpoint(ckpt_path)
    pending = [t for t in targets if t["id"] not in done]
    if not pending:
        print(f"[reguard] shard {args.shard}/{args.shards}: nothing pending "
              f"({len(done)} checkpointed)", flush=True)
        return done

    if args.shared_tmp:
        shared_tmp = args.shared_tmp
        os.makedirs(shared_tmp, exist_ok=True)
    else:
        shared_tmp = tempfile.mkdtemp(prefix=f"reguard_s{args.shard}_")
    print(f"[reguard] shard {args.shard}/{args.shards}: {len(pending)} pending "
          f"(skip {len(done)} done) | shared_tmp={shared_tmp} "
          f"| workers={args.workers}", flush=True)

    t0 = time.perf_counter()
    completed = 0
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = {
            ex.submit(guard_one, work[t["id"]], cand[t["id"]], shared_tmp): t["id"]
            for t in pending
        }
        for fut in as_completed(futs):
            rid = futs[fut]
            try:
                res = fut.result()
            except Exception as e:
                res = {"id": rid, "source": "floor",
                       "reject": f"reguard_exc: {type(e).__name__}"}
            append_checkpoint(ckpt_path, res)
            done[rid] = res
            completed += 1
            if res.get("source") == "idiomatic":
                print(f"  [+] {rid} -> idiomatic", flush=True)
            if completed % 50 == 0 or completed == len(pending):
                flipped = sum(1 for r in done.values() if r.get("source") == "idiomatic")
                print(f"  [{completed}/{len(pending)}] shard flipped={flipped} "
                      f"| {int(time.perf_counter() - t0)}s", flush=True)

    if not args.shared_tmp:
        shutil.rmtree(shared_tmp, ignore_errors=True)
    print(f"[reguard] shard {args.shard} done in {int(time.perf_counter() - t0)}s",
          flush=True)
    return done


def merge_checkpoints(ckpt_paths: list[Path], rows: list[dict]) -> int:
    results: dict[int, dict] = {}
    for p in ckpt_paths:
        results.update(load_checkpoint(p))

    flipped_ids = {rid for rid, r in results.items() if r.get("source") == "idiomatic"}
    rejects = {rid: r["reject"] for rid, r in results.items() if r.get("reject")}
    print(f"[reguard] merge: {len(results)} checkpointed, "
          f"{len(flipped_ids)} flipped idiomatic", flush=True)

    out_lines, changelog = [], []
    for r in rows:
        if r["id"] in flipped_ids:
            res = results[r["id"]]
            nr = dict(r)
            nr["source"] = "idiomatic"
            # The mechanical floor this rewrite just beat is the DPO rejected side.
            nr["rejected"] = r["jac"]
            nr.pop("reject_reason", None)
            nr["jac"] = res["jac"]
            out_lines.append(json.dumps(nr))
            changelog.append({"id": r["id"], "entrypoint": r["entrypoint"],
                              "chunk": r.get("chunk"),
                              "old_len": len(r.get("jac") or ""),
                              "new_len": len(res["jac"] or ""),
                              "reject": rejects.get(r["id"])})
        else:
            # Still floor: backfill the failed rewrite (DPO rejected side) if the
            # fresh guard captured one and the committed row is missing it.
            res = results.get(r["id"])
            if res and res.get("rejected_candidate") and not r.get("rejected"):
                nr = dict(r)
                nr["rejected"] = res["rejected_candidate"]
                nr["reject_reason"] = res.get("reject")
                out_lines.append(json.dumps(nr))
            else:
                out_lines.append(json.dumps(r))

    ts = int(time.time())
    bak = MASTER.with_name(MASTER.name + f".bak.{ts}")
    bak.write_text(MASTER.read_text())
    tmp = MASTER.with_name(MASTER.name + ".new")
    tmp.write_text("\n".join(out_lines) + "\n")
    os.replace(tmp, MASTER)
    (ROOT / "data/reguard_floors_changelog.jsonl").write_text(
        "\n".join(json.dumps(c) for c in changelog) + ("\n" if changelog else ""))
    print(f"[reguard] master rewritten ({len(out_lines)} records); backup: {bak.name}",
          flush=True)
    return len(flipped_ids)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--workers", type=int, default=8)
    ap.add_argument("--limit", type=int, default=0, help="cap targets (0=all)")
    ap.add_argument("--shard", type=int, default=0,
                    help="shard index (0-based); use with --shards")
    ap.add_argument("--shards", type=int, default=1,
                    help="total parallel shards (disjoint shared-tmp PG pools)")
    ap.add_argument("--shared-tmp",
                    help="TMPDIR for embedded Postgres (one per shard process)")
    ap.add_argument("--checkpoint-dir", default=str(CKPT_DIR))
    ap.add_argument("--merge", action="store_true",
                    help="merge all shard checkpoints into master and exit")
    args = ap.parse_args()

    if args.shards < 1:
        print("error: --shards must be >= 1", file=sys.stderr)
        return 2
    if args.shard < 0 or args.shard >= args.shards:
        print(f"error: --shard must be in [0, {args.shards})", file=sys.stderr)
        return 2

    ckpt_dir = Path(args.checkpoint_dir)
    ckpt_dir.mkdir(parents=True, exist_ok=True)

    if args.merge:
        ckpt_paths = sorted(ckpt_dir.glob("shard_*.jsonl"))
        if not ckpt_paths:
            print("[reguard] no checkpoints to merge", flush=True)
            return 1
        rows = [json.loads(l) for l in MASTER.read_text().splitlines() if l.strip()]
        merge_checkpoints(ckpt_paths, rows)
        return 0

    cand = load_candidates()
    work = load_work()
    rows = [json.loads(l) for l in MASTER.read_text().splitlines() if l.strip()]
    targets = build_targets(rows, cand, work, args.limit)

    if args.shards == 1:
        shard_targets_list = targets
        ckpt_path = ckpt_dir / "shard_0.jsonl"
        print(f"[reguard] {len(targets)} floor records with candidates/work "
              f"(of {sum(1 for r in rows if r.get('source')=='floor')} floor total)",
              flush=True)
    else:
        shard_targets_list = shard_targets(targets, args.shard, args.shards)
        ckpt_path = ckpt_dir / f"shard_{args.shard}.jsonl"
        print(f"[reguard] shard {args.shard}/{args.shards}: "
              f"{len(shard_targets_list)}/{len(targets)} targets", flush=True)

    run_shard(args, shard_targets_list, cand, work, ckpt_path)

    if args.shards == 1:
        merge_checkpoints([ckpt_path], rows)

    return 0


if __name__ == "__main__":
    sys.exit(main())
