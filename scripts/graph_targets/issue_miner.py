#!/usr/bin/env python3
"""Mine GitHub ISSUES describing graph-shaped problems — targets for Jac demos.

Sibling of js2jac_dataset/source/discover.py (repos) — this one searches
issues, not repositories. The thesis: projects manually implementing graphs
without naming them (visited sets, recursive parent walks, cascade deletes,
WITH RECURSIVE queries, dependency resolution) are the strongest showcase of
Jac's native edges/walkers.

A problem is graph-looking when it has: entities+relationships, traversal or
reachability, dependency ordering, propagation through connected objects,
cycles/paths/ancestry, or repeated joins across tables/types.

Stages (each resumable, merged by html_url into issues.jsonl):
  1. search   gh api search/issues over ~25 graph-signal phrase queries,
              throttled + rate-limit-retried (search API: 30 req/min)
  2. enrich   for top-scoring hits, pull comments + repo metadata
              (language, stars, activity) via the core API
  3. score    pure-Python rubric: relationship vocab, traversal vocab,
              manual-implementation evidence, perf complaints, domain fit,
              activity — minus assigned/rejected penalties
  4. prompts  emit one LLM extraction prompt per top-K issue: Entities /
              Edges / Required traversal / Current implementation / Why a
              graph representation helps / Smallest credible Jac contribution,
              plus the critical filter: "would Jac eliminate meaningful
              state-management or traversal machinery?"

Usage:
  python3 issue_miner.py                          # search + score
  python3 issue_miner.py --enrich 60              # + comments/repo metadata
  python3 issue_miner.py --prompts 20             # + prompt files for top 20
  python3 issue_miner.py --queries-file my.txt    # custom phrase list
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "data" / "graph_targets"
ISSUES_OUT = OUT_DIR / "issues.jsonl"
PROMPTS_DIR = OUT_DIR / "prompts"

# Search API: 30 req/min authenticated. Space calls just under that (same
# policy as source/discover.py) and sleep until window reset on 403/429.
SEARCH_MIN_INTERVAL = 2.1
CORE_MIN_INTERVAL = 0.35  # core API is 5000/hr; gentle pacing is plenty
_last_ts: dict[str, float] = {}


def _throttle(kind: str = "search") -> None:
    interval = SEARCH_MIN_INTERVAL if kind == "search" else CORE_MIN_INTERVAL
    wait = interval - (time.monotonic() - _last_ts.get(kind, 0.0))
    if wait > 0:
        time.sleep(wait)
    _last_ts[kind] = time.monotonic()


def _gh(path: str, fields: list[str] | None = None, jq: str | None = None,
        timeout: int = 60) -> tuple[int, str, str]:
    """One gh api call. Returns (rc, stdout, stderr)."""
    cmd = ["gh", "api", "-X", "GET", path]
    for f in fields or []:
        cmd += ["-f", f]
    if jq:
        cmd += ["--jq", jq]
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode, r.stdout, r.stderr
    except subprocess.TimeoutExpired:
        return 1, "", "timeout"


def _search_reset_in() -> int:
    rc, out, _ = _gh("rate_limit", jq=".resources.search.reset")
    if rc == 0 and out.strip().isdigit():
        return max(1, int(out.strip()) - int(time.time()) + 2)
    return 62


# ---- 1. queries ------------------------------------------------------------ #
# explicit: names the graph structure; hidden: manual-graph tells; domain:
# workflow/build/authz/lineage categories where graph semantics is core.
QUERIES: list[tuple[str, str]] = [
    ("explicit", '"dependency graph" performance'),
    ("explicit", '"circular dependency"'),
    ("explicit", '"transitive dependencies"'),
    ("explicit", '"impact analysis"'),
    ("explicit", '"execution order" dependencies'),
    ("explicit", '"relationship traversal"'),
    ("explicit", '"nested relationships"'),
    ("explicit", '"recursive query"'),
    ("explicit", '"shortest path"'),
    ("explicit", '"topological sort"'),
    ("explicit", '"data lineage"'),
    ("explicit", '"call graph"'),
    ("explicit", '"permission inheritance"'),
    ("hidden", '("recursive" OR "recursively") ("parent" OR "dependency")'),
    ("hidden", '"visited set"'),
    ("hidden", '"detect cycles"'),
    ("hidden", '"depends on" "order"'),
    ("hidden", '"related objects" performance'),
    ("hidden", '"multiple joins" hierarchy'),
    ("hidden", '"propagate" dependencies'),
    ("hidden", '"WITH RECURSIVE"'),
    ("hidden", '"recursive CTE"'),
    ("hidden", '"ancestors" "descendants" query'),
    ("hidden", '"cascade" delete "descendants"'),
    ("domain", '"dependency resolution" slow'),
    ("domain", '"unresolved dependency" cycle'),
    ("domain", 'workflow "task dependencies"'),
    ("domain", '"role hierarchy" permissions'),
    ("domain", '"lineage" "downstream" datasets'),
    # shape: schema-level tells — a graph encoded into relational tables
    ("shape", '"closure table"'),
    ("shape", '"nested set"'),
    ("shape", '"materialized path"'),
    ("shape", '"adjacency list" table'),
    ("shape", '"self-referencing" foreign key'),
    ("shape", '"parent_id" recursive'),
    # shape: runtime tells — relationships traversed or propagated
    ("shape", '"blast radius"'),
    ("shape", '"downstream" "recompute"'),
    ("shape", '"cache invalidation" dependencies'),
    ("shape", '"safe delete" referenced'),
    ("shape", '"orphaned" references'),
    ("shape", '"connected components"'),
    ("shape", '"all descendants"'),
    ("shape", '"mutual recursion"'),
    ("shape", '"dirty" "propagate" recompute'),
    # v2-refit intake (2026-09-14): query the families the refit kept —
    # concrete algorithm names predict landing (~/notes/osp_signal_refit.md)
    ("shape", '"transitive closure"'),
    ("hidden", '"cycle detection" graph'),
    ("explicit", '"graph traversal"'),
    ("hidden", '"hierarchical data" recursive query'),
    ("hidden", '"flatten" hierarchy'),
    ("hidden", '"find all children"'),
    ("hidden", '"walk the tree" recursively'),
    ("domain", '"bill of materials" explosion'),
    ("hidden", '"threaded comments" recursive'),
    ("hidden", '"infinite recursion" "stack overflow"'),
    # v3-refit intake (2026-09-15): cascade/adjacency/n+1 mechanism language —
    # the families the v3 refit up-weighted. Deliberately NO cycle-speak:
    # "cycle detection" was the worst repair-conversion signal in 56-74
    # (~/notes/osp_signal_refit_v3.md)
    ("domain", '"cascade delete" hierarchy'),
    ("hidden", '"on delete cascade"'),
    ("shape", '"cache invalidation" tree'),
    ("hidden", '"adjacency list" recursion'),
    ("shape", '"N+1" "parent"'),
    ("hidden", '"nested set" "adjacency list"'),
    ("explicit", '"hierarchical data" "N+1"'),
    ("hidden", '"descendants" "recursive query"'),
]

BASE_QUALIFIERS = "is:issue is:open"

# jq projection for search items — truncate bodies to keep the jsonl sane.
_SEARCH_JQ = (
    "{number, title, html_url, state,"
    " body: ((.body // \"\")[0:6000]),"
    " comments, reactions: (.reactions.total_count // 0),"
    " labels: [.labels[].name],"
    " assignees: [.assignees[].login],"
    " user: .user.login, created_at, updated_at,"
    " repo: .repository_url, comments_url}"
)


def search_issues(max_pages: int = 2, per_page: int = 100) -> list[dict]:
    """Run every query, dedupe by html_url. Returns hits with query provenance."""
    seen: dict[str, dict] = {}
    for cat, phrase in QUERIES:
        q = f"{BASE_QUALIFIERS} {phrase}"
        got = 0
        for page in range(1, max_pages + 1):
            while True:
                _throttle("search")
                rc, out, err = _gh(
                    "search/issues",
                    fields=[f"q={q}", f"per_page={per_page}", f"page={page}"],
                    jq=f".items[] | {_SEARCH_JQ}",
                )
                if rc == 0:
                    break
                if "rate limit" in (err or "").lower():
                    wait = _search_reset_in()
                    print(f"  ! search rate-limited; sleeping {wait}s", file=sys.stderr)
                    time.sleep(wait)
                    continue
                print(f"  ! gh error on [{phrase}]: {(err or '').strip()[:160]}",
                      file=sys.stderr)
                page = 10**9  # abort pagination for this query
                break
            lines = [ln for ln in out.splitlines() if ln.strip()] if rc == 0 else []
            if not lines:
                break
            for ln in lines:
                try:
                    it = json.loads(ln)
                except json.JSONDecodeError:
                    continue
                url = it.get("html_url")
                if not url:
                    continue
                got += 1
                if url in seen:
                    seen[url].setdefault("queries", []).append(f"{cat}:{phrase}")
                else:
                    it["queries"] = [f"{cat}:{phrase}"]
                    seen[url] = it
            if len(lines) < per_page:
                break
        print(f"[{cat:8}] {phrase[:46]:46} +{got:4} (total {len(seen)})",
              file=sys.stderr)
    return list(seen.values())


# ---- 2. enrichment ---------------------------------------------------------- #
def repo_slug(repo_url: str) -> str:
    # https://api.github.com/repos/owner/name -> owner/name
    return repo_url.rstrip("/").rsplit("/repos/", 1)[-1]


def enrich(hit: dict) -> dict:
    """Pull repo metadata + first page of comments. Mutates + returns hit."""
    slug = repo_slug(hit.get("repo") or "")
    if slug:
        _throttle("core")
        rc, out, _ = _gh(
            f"repos/{slug}",
            jq="{language, stars: .stargazers_count, pushed_at, "
               "size, description: ((.description // \"\")[0:200]), "
               "archived}",
        )
        if rc == 0 and out.strip():
            try:
                hit["repo_meta"] = json.loads(out)
            except json.JSONDecodeError:
                pass
    if hit.get("comments"):
        cu = hit.get("comments_url") or f"repos/{slug}/issues/{hit['number']}/comments"
        _throttle("core")
        rc, out, _ = _gh(
            f"{cu.removeprefix('https://api.github.com/')}",
            fields=["per_page=10"],
            jq=".[] | {user: .user.login, "
               "body: ((.body // \"\")[0:1200]), created_at, "
               "author_association}",
        )
        if rc == 0 and out.strip():
            try:
                hit["issue_comments"] = [json.loads(ln)
                                         for ln in out.splitlines() if ln.strip()]
            except json.JSONDecodeError:
                pass
    hit["enriched"] = True
    return hit


# ---- 3. scoring rubric ------------------------------------------------------- #
# Each family scores once (distinct-signal counting, not raw regex hits).
# Weights refit TWICE: v2 against luna-wave first-pass landing (batches 38-55,
# ~/notes/osp_signal_refit.md); v3 against POST-REPAIR gate passage on batches
# 56-74 (~/notes/osp_signal_refit_v3.md) — first-pass landing is gate-dominated
# (head 10% <= tail 19%); selection shows up in repairability (refit-pool
# failures converted 41.3% vs 18.2% fresh), so the target label is final
# manifest membership.
#
# v3 deltas vs final passage, 56-74 (n=181, base 40.3%):
#   KEPT/UP: adjacency +19.7 (n=10), n_plus_one +15.2 (n=9), recursive_cte
#   +5.1 (n=110), discussion +11.1 (n=72, bumped 2->3). cascade|invalidat
#   added @2 PROVISIONAL (n=8 current regime, +16 on era-mixed all-cohort).
#   DOWN/KILLED: cycle −13.5 final / −12.0 conversion at n≈65 → dropped;
#   ordering −13.7 (n=45) 3->1; bfs_dfs −4.6 (n=56) 3->2; queue_walk 0/6
#   final 2->1. Structural-vocabulary prose (cycle/ordering/DFS-speak) lifts
#   WORSE in the jac-only regime; concrete manual-impl evidence predicts.
_SIGNALS: list[tuple[str, str, int, int]] = [
    # (bucket, family, weight, cap, pattern) — title+body+labels+comments
    ("traversal", "recursive", 3, 8, r"\brecursi(?:ve|on|vely)\b|WITH RECURSIVE|recursive CTE"),
    ("traversal", "ordering", 1, 0, r"\btopolog(?:ical|y)|execution order|resolve order"),
    ("traversal", "bfs_dfs", 2, 0, r"\b(BFS|DFS|breadth[- ]first|depth[- ]first)\b"),
    ("manual_impl", "recursive_cte", 4, 8, r"WITH RECURSIVE|recursive CTE|connect by"),
    ("manual_impl", "adjacency", 3, 0, r"\badjacency (list|dict|matrix)|adj[_a-z]*\s*[:=]\s*[\[{]"),
    ("manual_impl", "queue_walk", 1, 0, r"\b(deque|popleft|pop\(0\)|queue\.(get|put))\b"),
    ("manual_impl", "memo_ancestors", 2, 0, r"\b(memoiz|cache).{0,40}(parent|ancestor|dependenc)"),
    ("manual_impl", "n_plus_one", 4, 0, r"N\+1|too many (quer|request)|query per (node|parent|item)"),
    ("manual_impl", "cascade", 2, 2, r"\bcascade\w*\b|on delete|invalidat\w*\b"),
    ("refactor", "refactor", 2, 2, r"\brefactor\w*\b|\brewrite\b|\brestructur\w*\b"),
]
NEG_LABELS = re.compile(r"wontfix|not planned|duplicate|out of scope|invalid", re.I)


def score(hit: dict) -> dict:
    """Rubric score + matched families. Mutates hit with {'score', 'matched'}."""
    text = " ".join([
        hit.get("title") or "",
        hit.get("body") or "",
        " ".join(hit.get("labels") or []),
        " ".join(c.get("body") or "" for c in hit.get("issue_comments") or []),
    ])
# (single explicit pass — per-bucket caps on distinct families, not raw hits)
    matched, total = {}, 0
    bucket_counts: dict[str, int] = {}
    bucket_caps = {}
    for bucket, _f, _w, cap, _p in _SIGNALS:
        bucket_caps.setdefault(bucket, cap)
    for bucket, family, weight, _cap, pat in _SIGNALS:
        if not re.search(pat, text, re.I):
            continue
        if bucket_counts.get(bucket, 0) >= bucket_caps[bucket]:
            continue
        bucket_counts[bucket] = bucket_counts.get(bucket, 0) + 1
        matched[f"{bucket}.{family}"] = weight
        total += weight
    # activity: discussion heat / reactions — both predict lift landing
    # (+21% / +32% on luna outcomes) and survive the jac-only regime
    # (discussion +11.1% final passage, n=72, wave 56-74). recent_update
    # dropped: 90% fire rate.
    if (hit.get("comments") or 0) > 2:
        total += 3
        matched["activity.discussion"] = 3
    if (hit.get("reactions") or 0) > 0:
        total += 2
        matched["activity.reactions"] = 2
    # penalties
    if hit.get("assignees"):
        total -= 6
        matched["penalty.assigned"] = -6
    if any(NEG_LABELS.search(l or "") for l in hit.get("labels") or []):
        total -= 8
        matched["penalty.rejected_label"] = -8
    if not (hit.get("body") or "").strip():
        total -= 5
        matched["penalty.no_body"] = -5
    hit["score"] = total
    hit["matched"] = matched
    return hit


# ---- 4. LLM prompt ----------------------------------------------------------- #
ANALYSIS_TEMPLATE = """\
You are evaluating whether a GitHub issue describes a graph-shaped problem
that the Jac programming language (native nodes, edges, and walkers —
traversal is a language primitive, not a library) would demonstrably improve.

The critical filter: would Jac eliminate meaningful state-management or
traversal machinery? Merely using a graph algorithm is NOT enough — a project
calling NetworkX for topological sorting is weak. A project maintaining
relationships across many classes, recursive queries, visited sets,
invalidation, and propagation logic is an excellent target.

ISSUE: {title}
URL: {url}
REPO: {repo} ({stars} stars, {language})
LABELS: {labels}
BODY:
{body}
COMMENTS:
{comments}

Produce exactly:
Entities:
Edges:
Required traversal:
Current implementation:
Why a graph representation helps:
Smallest credible Jac contribution:
Jac-fit gate: would replacing the current machinery with Jac's native
nodes/edges/walkers eliminate meaningful state-management or traversal code?
Answer honestly; score 0-10 (0 = graph use is incidental, 10 = core domain
is a graph, hand-rolled today).
jac_fit_score: <0-10>
"""


def build_prompt(hit: dict) -> str:
    rm = hit.get("repo_meta") or {}
    comments = hit.get("issue_comments") or []
    ctext = "\n".join(
        f"[{c.get('author_association', 'NONE')}] {c.get('user', '?')}: "
        f"{(c.get('body') or '').strip()[:600]}"
        for c in comments
    ) or "(none fetched)"
    return ANALYSIS_TEMPLATE.format(
        title=hit.get("title") or "",
        url=hit.get("html_url") or "",
        repo=repo_slug(hit.get("repo") or "?"),
        stars=rm.get("stars", "?"),
        language=rm.get("language", "?"),
        labels=", ".join(hit.get("labels") or []) or "(none)",
        body=(hit.get("body") or "").strip()[:8000] or "(empty)",
        comments=ctext,
    )


# ---- persistence (merge-on-write, resume-safe) -------------------------------- #
def load_existing(path: Path) -> dict[str, dict]:
    out: dict[str, dict] = {}
    if path.exists():
        for ln in path.read_text().splitlines():
            if not ln.strip():
                continue
            try:
                r = json.loads(ln)
            except json.JSONDecodeError:
                continue
            if r.get("html_url"):
                out[r["html_url"]] = r
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", default=str(ISSUES_OUT))
    ap.add_argument("--fresh", action="store_true",
                    help="overwrite instead of merging with existing results")
    ap.add_argument("--pages", type=int, default=2,
                    help="search result pages per query (100/page)")
    ap.add_argument("--enrich", type=int, default=0,
                    help="enrich top N scored hits with comments + repo meta")
    ap.add_argument("--prompts", type=int, default=0,
                    help="write LLM prompts for top N hits")
    ap.add_argument("--min-score", type=int, default=8,
                    help="score floor for prompt emission")
    ap.add_argument("--max-repos", type=int, default=0,
                    help="cap distinct repos: enrich/emit the single best issue "
                         "per repo, up to N repos (0 = no cap, all issues)")
    ap.add_argument("--queries-file", default=None,
                    help="file with one 'category<TAB>query' per line, "
                         "replacing the built-in list")
    args = ap.parse_args()

    global QUERIES
    if args.queries_file:
        qf = Path(args.queries_file)
        QUERIES = []
        for ln in qf.read_text().splitlines():
            ln = ln.strip()
            if not ln or ln.startswith("#"):
                continue
            cat, _, phrase = ln.partition("\t")
            QUERIES.append((cat.strip() or "custom",
                            phrase.strip() or cat.strip()))
        print(f"loaded {len(QUERIES)} queries from {qf}", file=sys.stderr)

    outp = Path(args.out)
    outp.parent.mkdir(parents=True, exist_ok=True)
    existing = {} if args.fresh else load_existing(outp)

    # 1. search
    hits = search_issues(max_pages=args.pages)
    print(f"\nsearch: {len(hits)} unique issues across {len(QUERIES)} queries",
          file=sys.stderr)

    # merge (existing enriched records win their fields back)
    by_url = existing
    for h in hits:
        old = by_url.get(h["html_url"])
        if old:
            old.setdefault("queries", []).extend(
                q for q in h["queries"] if q not in old["queries"])
        else:
            by_url[h["html_url"]] = h

    # 2+3. score all, then enrich the top slice
    records = list(by_url.values())
    for r in records:
        score(r)
    records.sort(key=lambda r: r.get("score", 0), reverse=True)

    if args.enrich:
        # with --max-repos: the best issue of each of the top N repos;
        # otherwise the plain top-N issues (may repeat a repo)
        if args.max_repos:
            sel: set[str] = set()
            targets = []
            for r in records:
                if len(sel) >= args.max_repos:
                    break
                rk = r.get("repo") or r["html_url"]
                if rk in sel:
                    continue
                sel.add(rk)
                targets.append(r)
        else:
            targets = records[:args.enrich]
        todo = [r for r in targets if not r.get("enriched")]
        print(f"enriching {len(todo)} of {len(targets)} selected "
              f"({len(targets) - len(todo)} already done)",
              file=sys.stderr)
        for i, r in enumerate(todo, 1):
            enrich(r)
            score(r)  # comments may add signals
            if i % 20 == 0:
                print(f"  enriched {i}/{len(todo)}", file=sys.stderr)
        records.sort(key=lambda r: r.get("score", 0), reverse=True)

    with outp.open("w") as f:
        for r in records:
            f.write(json.dumps(r, sort_keys=True) + "\n")

    # summary
    import collections
    fams = collections.Counter()
    for r in records:
        for k in (r.get("matched") or {}):
            fams[k.split(".", 1)[0]] += 1
    strong = [r for r in records if r.get("score", 0) >= args.min_score]
    print(f"\nwrote {len(records)} -> {outp}", file=sys.stderr)
    print(f"bucket hits: {dict(fams.most_common())}", file=sys.stderr)
    print(f"score>={args.min_score}: {len(strong)}", file=sys.stderr)
    for r in records[:15]:
        rm = r.get("repo_meta") or {}
        print(f"  {r.get('score', 0):3} {repo_slug(r.get('repo') or '?'):40} "
              f"#{r.get('number')} {rm.get('stars', '?')}* "
              f"{(r.get('title') or '')[:70]}", file=sys.stderr)

    # 4. prompt files (respects --max-repos selection + score floor)
    if args.prompts:
        if args.max_repos:
            sel2: set[str] = set()
            prompt_targets = []
            for r in records:
                if len(sel2) >= args.max_repos:
                    break
                rk = r.get("repo") or r["html_url"]
                if rk in sel2:
                    continue
                sel2.add(rk)
                prompt_targets.append(r)
        else:
            prompt_targets = records
        PROMPTS_DIR.mkdir(parents=True, exist_ok=True)
        n = 0
        for r in records:
            if n >= args.prompts:
                break
            if r.get("score", 0) < args.min_score:
                continue
            slug = re.sub(r"[^a-z0-9]+", "-",
                          (r.get("title") or "issue").lower())[:60].strip("-")
            owner_repo = repo_slug(r.get("repo") or "x").replace("/", "__")
            pf = PROMPTS_DIR / f"{r.get('score', 0):03}_{owner_repo}__{r.get('number')}__{slug}.md"
            pf.write_text(build_prompt(r))
            n += 1
        print(f"wrote {n} prompts -> {PROMPTS_DIR}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
