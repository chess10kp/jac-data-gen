#!/usr/bin/env python3
"""Rebuild checked non-SF jachacks datasets from the (possibly repaired) tree.

Reads the live tree at JH_TREE (default /tmp/jachacks_nonsf — subagents fix in
place), re-runs `jac check` per repo, and emits the passing records into the
*_checked.jsonl files. Repaired records get `repaired_by: 'subagent'` and
`original_sha` provenance fields.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
TREE = Path(os.environ.get("JH_TREE", "/tmp/jachacks_nonsf"))
SUM_RE = re.compile(r"^(\S.*?\.jac) - (\d+) errors?,")
TGT_RE = re.compile(r"^\s*-->\s*(\S+?\.jac):\d+:\d+")
DIAG_START = re.compile(r"^\s*[✖⚠]")


def check_repo(repo: str) -> tuple[set[str], set[str]]:
    """Return (failed_files, err_targeted_files) for one repo."""
    p = subprocess.run(["jac", "check", "-j", "8", repo], cwd=TREE,
                       capture_output=True, text=True, timeout=600)
    txt = p.stdout + p.stderr
    failed, errtgt = set(), set()
    lines = txt.splitlines()
    blocks, cur = [], None
    for ln in lines:
        if DIAG_START.match(ln):
            if cur:
                blocks.append(cur)
            cur = [ln]
        elif cur is not None:
            if re.match(r"^\S", ln):
                blocks.append(cur)
                cur = None
            else:
                cur.append(ln)
    if cur:
        blocks.append(cur)
    for b in blocks:
        if not b[0].lstrip().startswith("✖"):
            continue
        for m in (TGT_RE.match(x) for x in b):
            if m:
                pp = m.group(1)
                i = pp.find(repo + "/")
                if i >= 0:
                    errtgt.add(pp[i + len(repo) + 1:])
                break
    for ln in lines:
        m = SUM_RE.match(ln.strip())
        if m and int(m.group(2)) > 0:
            pth = m.group(1)
            if pth.startswith(repo + "/"):
                pth = pth[len(repo) + 1:]
            failed.add(pth)
    return failed, errtgt


def parent_of_impl(rel: str) -> str | None:
    d, b = rel.rsplit("/", 1)
    if d.endswith("/impl") and b.endswith(".impl.jac"):
        return d[:-5] + "/" + b[:-len(".impl.jac")] + ".jac"
    return None


def main() -> int:
    records = {}
    for src in ("spring", "2026"):
        for line in open(REPO / "data" / f"jachacks_{src}_jac_files_filtered.jsonl"):
            r = json.loads(line)
            records[f"{r['dirname']}/{r['file_path']}"] = r
    repos = sorted({r["dirname"] for r in records.values()})
    print(f"checking {len(repos)} repos...", flush=True)

    failed: set[str] = set()
    for i, repo in enumerate(repos):
        mf, et = check_repo(repo)
        for f in mf | et:
            failed.add(f"{repo}/{f}")
        print(f"  [{i+1}/{len(repos)}] {repo}: {len(mf | et)} failing", flush=True)

    # impl parts inherit parent verdict
    for rel in list(failed):
        par = parent_of_impl(rel)
        if par and par in failed:
            pass  # already failed
    for rel in [k for k in records if k not in failed]:
        par = parent_of_impl(rel)
        if par and par in failed:
            failed.add(rel)

    counts = {}
    renamed = {}
    for src in ("spring", "2026"):
        out = REPO / "data" / f"jachacks_{src}_jac_files_checked.jsonl"
        n = 0
        with open(out, "w") as g:
            for rel, r in records.items():
                if r["source"] != f"jachacks-{src}":
                    continue
                if rel in failed:
                    continue
                live_path = TREE / rel
                r = dict(r)
                if not live_path.exists():
                    # agent may have stripped a companion suffix (.cl/.sv)
                    alt = re.sub(r"\.(cl|sv)\.jac$", ".jac", rel)
                    if alt in failed:
                        continue
                    if (TREE / alt).exists():
                        r["renamed_from"] = r["file_path"]
                        r["file_path"] = alt.split("/", 1)[1]
                        renamed[rel] = alt
                        live_path = TREE / alt
                    else:
                        print("MISSING:", rel)
                        continue
                live = live_path.read_text()
                if live != r["jac"]:
                    r = dict(r)
                    r["original_sha"] = hashlib.sha256(r["jac"].encode()).hexdigest()[:12]
                    r["jac"] = live
                    r["chars"] = len(live)
                    r["lines"] = live.count("\n") + 1
                    r["repaired_by"] = "subagent"
                g.write(json.dumps(r) + "\n")
                n += 1
        counts[src] = n
    combined = REPO / "data" / "jachacks_nonsf_jac_files_checked.jsonl"
    with open(combined, "w") as g:
        for src in ("spring", "2026"):
            for line in open(REPO / "data" / f"jachacks_{src}_jac_files_checked.jsonl"):
                g.write(line)
    print("checked:", counts, "combined:", sum(counts.values()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
