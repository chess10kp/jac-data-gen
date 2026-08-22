"""Tier graded Jac samples into T0-T3 and emit DPO preference pairs.

This is the DPO preference-labeler ("job B"): it consumes the output of
`eval_jac.py` and turns it into (chosen, rejected) pairs. It runs no Jac
subprocesses of its own -- every signal already lives in `results.jsonl`.

Tiers (higher is better; a pair is any within-problem gap of >= --min-margin):

  T0  does not compile          (`jac check` failed / no Jac extracted)
  T1  compiles, wrong behavior  (`jac test` failed on hidden tests)
  T2  correct, non-idiomatic    (passes, but has transpiler residue / smells)
  T3  correct and idiomatic     (passes, zero smells, contract satisfied)

A compile-only problem (no hidden tests) can never assign T1: behavior is
unproven, so a passing-check sample lands in T2/T3 and a failing one in T0.

Inputs are the SAME `--problems` and `--samples` given to `eval_jac.py`, plus
the `results.jsonl` it produced. Sources are recovered from the samples and
sha-verified against each graded row so tier labels can never drift onto the
wrong completion.

Outputs (in --out-dir):
  results_tiered.jsonl   every graded row + {tier, tier_reasons}
  dpo_pairs.jsonl        {problem_id, chosen, rejected, ...} preference pairs
  tier_summary.json      tier histogram + pair counts

Usage:
  python scripts/tier_pairs.py \
      --problems problems.jsonl --samples samples.jsonl \
      --results out/results.jsonl --out-dir out/
"""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

import eval_jac

# --- tier classification -----------------------------------------------------

# Statuses that are the tool's fault, not the model's: excluded from tiering
# entirely so they never poison a preference pair.
INFRA_STATUSES = {"infra_error", "tool_crash"}

# Static-diagnostic fields that mark a sample as non-idiomatic (T2 not T3).
# Each maps to a human reason emitted in tier_reasons.
SMELL_CHECKS: list[tuple[str, str]] = [
    ("python_syntax_smell", "python_syntax"),
    ("import_py_smell", "import_py"),
    ("included_test_blocks", "embedded_test_blocks"),
]
COUNT_SMELLS: list[tuple[str, str]] = [
    ("dynamic_type_mentions", "dynamic_types"),
    ("range_len_loops", "range_len_loop"),
]


def smell_reasons(row: dict[str, Any]) -> list[str]:
    """Non-idiomatic markers for a passing sample; empty means clean (T3)."""
    static = row.get("static") or {}
    reasons: list[str] = []
    for field, label in SMELL_CHECKS:
        if static.get(field):
            reasons.append(label)
    for field, label in COUNT_SMELLS:
        if int(static.get(field, 0) or 0) > 0:
            reasons.append(label)
    if not row.get("contract_pass", True):
        reasons.append("contract_fail")
    return reasons


def tier_of(row: dict[str, Any]) -> tuple[int | None, list[str]]:
    """Classify one graded row into a tier and its reasons.

    Returns (None, ["infra"]) for tool-caused failures that must be dropped.
    Pure: depends only on fields eval_jac.py already wrote.
    """
    status = str(row.get("status"))
    if status in INFRA_STATUSES:
        return None, ["infra"]

    if not row.get("check_pass"):
        reason = "no_jac_extracted" if status == "extract_fail" else "check_fail"
        return 0, [reason]

    # Compiles. If the problem carries hidden tests, behavior must pass.
    if row.get("has_behavior_tests"):
        if not row.get("test_pass"):
            return 1, ["test_fail"]

    # Correct (or compile-only + compiles): idiomaticity splits T2 vs T3.
    reasons = smell_reasons(row)
    if reasons:
        return 2, reasons
    return 3, ["clean"]


# --- source recovery ---------------------------------------------------------


def model_generation(sample: dict[str, Any]) -> str | None:
    """The text the model actually produced for this sample.

    For a completion task that is only the continuation (not prefix+suffix);
    that continuation is what a DPO pair's chosen/rejected must contain. For a
    whole-answer sample it is the full extracted source.
    """
    if "completion" in sample:
        generation, error = eval_jac.extract_jac(str(sample.get("completion", "")))
        return None if error else generation
    for key in ("jac", "candidate", "output"):
        if key in sample:
            generation, error = eval_jac.extract_jac(str(sample.get(key, "")))
            return None if error else generation
    return None


def build_source_index(
    problems: list[dict[str, Any]], samples: list[dict[str, Any]]
) -> dict[tuple[str, str], dict[str, str]]:
    """Map (problem_id, sample_id) -> {assembled, generation, prompt}.

    `assembled` is the full compilable source (for sha-verify against the graded
    row); `generation` is what the model emitted (for the DPO pair); `prompt` is
    the problem instruction. Mirrors eval_jac's own assembly.
    """
    by_id = {str(problem["id"]): problem for problem in problems}
    index: dict[tuple[str, str], dict[str, str]] = {}
    for fallback_index, sample in enumerate(samples):
        problem_id = str(sample["problem_id"])
        sample_id = str(sample.get("sample_id", fallback_index))
        problem = by_id.get(problem_id)
        if problem is None:
            continue
        assembled, error = eval_jac.assemble_source(problem, sample)
        if error or assembled is None:
            continue
        generation = model_generation(sample)
        if generation is None:
            continue
        index[(problem_id, sample_id)] = {
            "assembled": assembled,
            "generation": generation,
            "prompt": str(problem.get("prompt", "")),
        }
    return index


def entry_for_row(
    row: dict[str, Any], index: dict[tuple[str, str], dict[str, str]]
) -> dict[str, str] | None:
    """Recover a row's entry and verify its sha matches the graded record."""
    key = (str(row["problem_id"]), str(row["sample_id"]))
    entry = index.get(key)
    if entry is None:
        return None
    recorded = row.get("source_sha256")
    if recorded:
        actual = hashlib.sha256(entry["assembled"].encode()).hexdigest()
        if actual != recorded:
            return None
    return entry


# --- pair emission -----------------------------------------------------------


def fence(text: str) -> str:
    return f"```jac\n{text}\n```"


def emit_pairs(
    tiered: list[dict[str, Any]],
    index: dict[tuple[str, str], dict[str, str]],
    *,
    strategy: str,
    min_margin: int,
    fenced: bool,
) -> list[dict[str, Any]]:
    """Form (chosen, rejected) pairs from within-problem tier gaps.

    chosen/rejected carry the model's generation (optionally ```jac-fenced).
    Samples with the same generation are deduped to the higher tier so an
    identical answer is never both chosen and rejected.
    """
    by_problem: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in tiered:
        if row.get("tier") is None:
            continue
        entry = entry_for_row(row, index)
        if entry is None:
            continue
        by_problem[str(row["problem_id"])].append({**row, "_entry": entry})

    wrap = fence if fenced else (lambda text: text)
    pairs: list[dict[str, Any]] = []
    for problem_id, rows in by_problem.items():
        # Dedupe identical generations, keeping the highest tier seen.
        best_by_gen: dict[str, dict[str, Any]] = {}
        for row in rows:
            gen = row["_entry"]["generation"]
            existing = best_by_gen.get(gen)
            if existing is None or row["tier"] > existing["tier"]:
                best_by_gen[gen] = row
        unique = sorted(best_by_gen.values(), key=lambda r: r["tier"], reverse=True)
        if len(unique) < 2:
            continue

        selected: list[tuple[dict[str, Any], dict[str, Any]]] = []
        if strategy == "best-vs-rest":
            top = unique[0]
            for other in unique[1:]:
                if top["tier"] - other["tier"] >= min_margin:
                    selected.append((top, other))
        elif strategy == "adjacent":
            for higher, lower in zip(unique, unique[1:]):
                if higher["tier"] - lower["tier"] >= min_margin:
                    selected.append((higher, lower))
        else:  # "all"
            for i, higher in enumerate(unique):
                for lower in unique[i + 1 :]:
                    if higher["tier"] - lower["tier"] >= min_margin:
                        selected.append((higher, lower))

        for chosen, rejected in selected:
            pairs.append(
                {
                    "prompt": chosen["_entry"]["prompt"],
                    "chosen": wrap(chosen["_entry"]["generation"]),
                    "rejected": wrap(rejected["_entry"]["generation"]),
                    "problem_id": problem_id,
                    "chosen_tier": chosen["tier"],
                    "rejected_tier": rejected["tier"],
                    "margin": chosen["tier"] - rejected["tier"],
                    "chosen_sample_id": chosen["sample_id"],
                    "rejected_sample_id": rejected["sample_id"],
                    "rejected_reasons": rejected.get("tier_reasons", []),
                }
            )
    return pairs


# --- driver ------------------------------------------------------------------


def mean(values: Iterable[float]) -> float | None:
    items = list(values)
    return round(sum(items) / len(items), 6) if items else None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--problems", type=Path, required=True)
    parser.add_argument("--samples", type=Path, required=True)
    parser.add_argument(
        "--results",
        type=Path,
        required=True,
        help="results.jsonl produced by eval_jac.py over the same inputs",
    )
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument(
        "--pair-strategy",
        choices=("best-vs-rest", "adjacent", "all"),
        default="best-vs-rest",
    )
    parser.add_argument(
        "--min-margin",
        type=int,
        default=1,
        help="minimum tier gap for a pair (e.g. 2 keeps only T3-vs-T1 and wider)",
    )
    parser.add_argument(
        "--fenced",
        action="store_true",
        help="wrap chosen/rejected in ```jac fences (match a fenced prompt style)",
    )
    args = parser.parse_args()
    if args.min_margin < 1:
        parser.error("--min-margin must be >= 1")

    problems = eval_jac.read_jsonl(args.problems)
    samples = eval_jac.read_jsonl(args.samples)
    results = eval_jac.read_jsonl(args.results)
    args.out_dir.mkdir(parents=True, exist_ok=True)

    tiered: list[dict[str, Any]] = []
    for row in results:
        tier, reasons = tier_of(row)
        tiered.append({**row, "tier": tier, "tier_reasons": reasons})

    index = build_source_index(problems, samples)
    pairs = emit_pairs(
        tiered,
        index,
        strategy=args.pair_strategy,
        min_margin=args.min_margin,
        fenced=args.fenced,
    )

    tiered_path = args.out_dir / "results_tiered.jsonl"
    tiered_path.write_text(
        "".join(json.dumps(row, sort_keys=True) + "\n" for row in tiered),
        encoding="utf-8",
    )
    pairs_path = args.out_dir / "dpo_pairs.jsonl"
    pairs_path.write_text(
        "".join(json.dumps(pair, sort_keys=True) + "\n" for pair in pairs),
        encoding="utf-8",
    )
    # Trainer-ready view: only the three keys mlx_dpo/train.jsonl expects.
    train_path = args.out_dir / "dpo_train.jsonl"
    train_path.write_text(
        "".join(
            json.dumps(
                {"prompt": p["prompt"], "chosen": p["chosen"], "rejected": p["rejected"]}
            )
            + "\n"
            for p in pairs
        ),
        encoding="utf-8",
    )

    tier_counts = Counter(
        f"T{row['tier']}" if row["tier"] is not None else "dropped_infra"
        for row in tiered
    )
    margin_counts = Counter(str(pair["margin"]) for pair in pairs)
    problems_with_pairs = len({pair["problem_id"] for pair in pairs})
    summary = {
        "schema_version": 1,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "configuration": {
            "pair_strategy": args.pair_strategy,
            "min_margin": args.min_margin,
            "results_sha256": eval_jac.sha256_file(args.results),
        },
        "samples": len(tiered),
        "tier_counts": dict(sorted(tier_counts.items())),
        "recovered_sources": len(index),
        "pairs": len(pairs),
        "pairs_by_margin": dict(sorted(margin_counts.items())),
        "problems_with_pairs": problems_with_pairs,
        "notes": [
            "T1 requires hidden behavior tests; compile-only problems skip it",
            "identical sources deduped to the higher tier before pairing",
            "smells drive T2 vs T3 -- reward-hacking them is the intended DPO signal",
        ],
    }
    summary_path = args.out_dir / "tier_summary.json"
    summary_path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")

    print(json.dumps(summary, indent=2, sort_keys=True))
    print(f"wrote {tiered_path}")
    print(f"wrote {pairs_path}")
    print(f"wrote {train_path}")
    print(f"wrote {summary_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
