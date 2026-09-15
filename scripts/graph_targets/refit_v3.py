#!/usr/bin/env python3
"""Refit v3: score signals against POST-REPAIR gate passage (no API calls).

v2 refit (~/notes/osp_signal_refit.md) used first-pass landing on batches
38-55. Wave 56-74 showed first-pass landing is gate-dominated (head 10% <=
tail 19%) while v2 selection predicts REPAIRABILITY (32% vs 20% conversion).
v3 therefore relabels every assigned issue with its FINAL manifest state
(post-repair gate passage) and re-runs the family analysis, plus a
repair-conversion analysis on first-pass failures.

Inputs (all on disk, no API):
  data/osp_lifts/assignments/issues_N_assign.json   assigned issues + signals
  data/osp_lifts/issues_N.jsonl                     final manifests (label)
  runs/repair_N.log                                 'reuse jac/guards' = first-pass
  data/graph_targets/issues.jsonl                   full text for re-matching

Caveat: first-pass vs final distinction only exists for batches 56-74 (the
repair tier); for <=55 first_pass == final. Analysis splits cohorts so the
regime shift (luna-era 56% base vs jac-only 31.5% base) doesn't smear.

Usage:
  python3 scripts/graph_targets/refit_v3.py                 # full tables
  python3 scripts/graph_targets/refit_v3.py --cohort 56-74  # one cohort only
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "graph_targets"))
import issue_miner as im  # noqa: E402

BASE = ROOT / "data" / "osp_lifts"
IG = BASE / "issue_gen"

# v1 noise families killed by the v2 refit — re-tested here against the
# final-passage and repair-conversion labels (patterns verbatim from the
# pre-refit miner, git e6c4c21f~1).
V1_KILLED = [
    ("relationship.parent_child", r"\b(parent|child(?:ren)?|ancestor|descendant)\b"),
    ("relationship.depends", r"\bdepend(?:s|ency|encies|ent)?\b|\bprerequisite"),
    ("relationship.reference", r"\b(refers? to|references?|linked? to|belongs to)\b"),
    ("traversal.walk", r"\b(traverse|traversal|walk(?:ing)? the)\b"),
    ("traversal.path_reach", r"\b(path|reachab(?:le|ility)|shortest path)\b"),
    ("manual_impl.visited_set", r"\b(visited|seen)\s+set\b"),
    ("perf.pain", r"\b(slow|performance|timeout|hang|quadratic|exponential|O\(n\^?2\)|minutes to)\b"),
    ("domain.workflow_dag", r"\b(workflow|pipeline|DAG|task dependencies?)\b"),
    ("domain.build_pkg", r"\b(build|compile|make(target)?|package|module resolution|import cycle)\b"),
    ("domain.authz", r"\b(permss?ion|role (hierarchy|inherit)|group membership|RBAC|ACL)\b"),
    ("domain.lineage", r"\b(lineage|provenance|upstream|downstream|impact analysis)\b"),
    ("activity.recent_update", r"\b(recently updated|last (week|month)|stale)\b"),
]

# candidate new text features for v3 (title+body only — cheap, minable)
CANDIDATES = [
    ("cand.tree_traversal", r"\b(tree traversal|travers(?:e|ing) the tree)\b"),
    ("cand.hierarchy_flatten", r"\bflatten\w*\b"),
    ("cand.transitive", r"\btransitive (closure|reduction|dependenc)\w*\b"),
    ("cand.cascade", r"\bcascade\w*\b|on delete"),
    ("cand.ancestor_query", r"\b(all (ancestors|descendants)|descendant nodes?)\b"),
    ("cand.cycle_detect", r"\bcycle detection|detect cycles\b"),
    ("cand.reorder", r"\bre-?order\w*\b|correct order\b"),
    ("cand.invalidat", r"\binvalidate\w*\b"),
    ("cand.dedup_seen", r"\b(already (seen|visited|processed)|deduplicat\w*)\b"),
    ("cand.state_words", r"\b(state|snapshot|rollback|undo)\b"),
    ("cand.repro_len", None),  # handled specially: body length quartile
]


def assigned_issues() -> list[dict]:
    """All assigned issues with batch, stored signals, score."""
    out = []
    for f in sorted((BASE / "assignments").glob("issues_*_assign.json")):
        m = re.fullmatch(r"issues_(\d+)_assign\.json", f.name)
        if not m:
            continue
        for r in json.loads(f.read_text()).get("records", []):
            r["batch"] = int(m.group(1))
            out.append(r)
    return out


def final_passed(batch: int, repo: str, issue: int) -> bool:
    mp = BASE / f"issues_{batch}.jsonl"
    if not mp.exists():
        return False
    for line in mp.read_text().splitlines():
        if not line.strip():
            continue
        p = json.loads(line)["provenance"]
        if p["repo"] == repo and p["issue"] == issue:
            return True
    return False


def first_pass_sets() -> dict[int, set[str]]:
    """batch -> stems that already passed before repair round 1."""
    out: dict[int, set[str]] = {}
    for b in range(56, 75):
        log = ROOT / "runs" / f"repair_{b}.log"
        stems: set[str] = set()
        if log.exists():
            for line in log.read_text().splitlines():
                if ": reuse jac/guards" in line:
                    stems.add(line.split(":")[0])
        out[b] = stems
    return out


def stem_to_issue(stem: str) -> tuple[str, int] | None:
    """iss_{owner}__{name}__{issue} -> (owner/name, issue); name may contain __."""
    if not stem.startswith("iss_"):
        return None
    rest = stem[4:]
    tail = rest.rsplit("__", 1)
    if len(tail) != 2 or not tail[1].isdigit():
        return None
    issue = int(tail[1])
    head = tail[0]
    owner, name = head.split("__", 1)
    return f"{owner}/{name}", issue


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--cohort", type=str, default=None, help="e.g. 56-74")
    args = ap.parse_args()

    pool: dict[tuple[str, int], dict] = {}
    pool_path = ROOT / "data" / "graph_targets" / "issues.jsonl"
    with pool_path.open() as fh:
        for line in fh:
            if not line.strip():
                continue
            h = json.loads(line)
            url = h.get("html_url") or ""          # github.com/{owner}/{name}/issues/{n}
            api = h.get("repo") or ""              # api.github.com/repos/{owner}/{name}
            tail = url.split("github.com/")[-1] if "github.com/" in url else api.split("/repos/")[-1]
            repo_key = "/".join(tail.split("/")[:2]) if "/" in tail else tail
            pool[(repo_key, int(h.get("number", 0)))] = h

    fp = first_pass_sets()
    rows = []
    for a in assigned_issues():
        if args.cohort:
            lo, hi = (int(x) for x in args.cohort.split("-"))
            if not (lo <= a["batch"] <= hi):
                continue
        repo, issue = a["repo"], a["issue"]
        h = pool.get((repo, issue)) or {}
        text = " ".join([
            h.get("title") or a.get("title") or "",
            h.get("body") or a.get("body") or "",
            " ".join(h.get("labels") or []),
            " ".join(c.get("body") or "" for c in h.get("issue_comments") or []),
        ])
        # fresh v2-family match on full text (stored signals may pre-date v2)
        matched = {}
        for bucket, family, _w, _cap, pat in im._SIGNALS:
            if re.search(pat, text, re.I):
                matched[f"{bucket}.{family}"] = _w
        if (h.get("comments") or 0) > 2:
            matched["activity.discussion"] = 2
        if (h.get("reactions") or 0) > 0:
            matched["activity.reactions"] = 2
        fin = final_passed(a["batch"], repo, issue)
        stem = f"iss_{repo.replace('/', '__')}__{issue}"
        # repair-log stems use owner__name__issue; match by (repo, issue) scan
        first = repo and issue and any(
            (pair := stem_to_issue(s)) == (repo, issue) for s in fp.get(a["batch"], ())
        )
        if a["batch"] <= 55:
            first = fin  # no repair tier existed
        rows.append({
            "batch": a["batch"], "repo": repo, "issue": issue,
            "v2score": a.get("score"), "matched": matched, "text": text,
            "first": bool(first), "final": fin,
            "repaired": fin and not first,
        })

    def rate(rs: list[dict], key: str) -> tuple[int, float]:
        n = len(rs)
        k = sum(1 for r in rs if r[key])
        return n, (k / n * 100 if n else 0.0)

    for label in ("first", "final"):
        n, pct = rate(rows, label)
        print(f"== cohort n={n}  {label}-pass {pct:.1f}%")

    def table(label: str, subset: list[dict], fams: list[tuple[str, str]]):
        base = sum(1 for r in subset if r[label]) / max(1, len(subset)) * 100
        print(f"\n-- {label} (base {base:.1f}%, n={len(subset)}) --")
        stats = []
        for name, pat in fams:
            fired = [r for r in subset if re.search(pat, r["text"], re.I)]
            if not fired:
                continue
            n, pct = rate(fired, label)
            stats.append((pct - base, n, name, pct))
        for delta, n, name, pct in sorted(stats, reverse=True):
            print(f"  {name:34s} n={n:3d}  {pct:5.1f}%  delta {delta:+.1f}")

    fams = [(f"{b}.{f}", p) for b, f, _w, _c, p in im._SIGNALS]
    print("\n=== V2 FAMILIES vs final passage ===")
    table("final", rows, fams)
    print("\n=== ACTIVITY (matched-dict) vs final passage ===")
    for fam in ("activity.discussion", "activity.reactions"):
        fired = [r for r in rows if fam in r["matched"]]
        if fired:
            base = sum(1 for r in rows if r["final"]) / max(1, len(rows)) * 100
            n, pct = rate(fired, "final")
            print(f"  {fam:34s} n={n:3d}  {pct:5.1f}%  delta {pct - base:+.1f}")
    print("\n=== V1 KILLED families vs final passage (re-test) ===")
    table("final", rows, V1_KILLED)

    fresh = [r for r in rows if r["batch"] >= 56 and not r["first"]]
    if fresh:
        print("\n=== REPAIR CONVERSION among first-pass failures (56-74) ===")
        table("repaired", fresh, [c for c in fams + V1_KILLED + CANDIDATES if c[1]])
        # v2 score quartiles vs conversion
        print("\n-- v2 score bands vs conversion --")
        for lo, hi in ((0, 8), (9, 9), (10, 10), (11, 99)):
            band = [r for r in fresh if lo <= (r["v2score"] or 0) <= hi]
            n, pct = rate(band, "repaired")
            if n:
                print(f"  score {lo}-{hi}: n={n:3d} converted {pct:5.1f}%")
        # cohort split: refit pool (56-66, v2-selected) vs fresh-mined (67-74)
        print("\n-- cohort vs conversion / final --")
        for cname, pred in (("refit 56-66", lambda r: 56 <= r["batch"] <= 66),
                            ("fresh 67-74", lambda r: r["batch"] >= 67)):
            co = [r for r in fresh if pred(r)]
            n, pct = rate(co, "repaired")
            nall, pall = rate([r for r in rows if pred(r)], "final")
            if nall:
                print(f"  {cname}: fails n={n:3d} converted {pct:5.1f}%   "
                      f"| all n={nall:3d} final {pall:5.1f}%")

    print("\n=== CANDIDATE features vs final passage (all cohorts) ===")
    table("final", rows, [c for c in CANDIDATES if c[1]])

    out = ROOT / "data" / "graph_targets" / "refit_v3_labels.jsonl"
    with out.open("w") as f:
        for r in rows:
            f.write(json.dumps({k: r[k] for k in
                                ("batch", "repo", "issue", "v2score",
                                 "matched", "first", "final", "repaired")}) + "\n")
    print(f"\nlabels written: {out} ({len(rows)} rows)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
