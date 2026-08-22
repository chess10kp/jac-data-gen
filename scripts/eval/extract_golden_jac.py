#!/usr/bin/env python3
"""Extract every ```jac fenced block from golden_client.jsonl into .jac files.

One file per fenced block. Records with a single block write <id>.jac; records
with N>1 blocks write <id>.jac, <id>__part2.jac, ..., <id>__partN.jac (in the
order the blocks appear across the assistant turns).

Quality filters / collisions:
  * Blocks with no real newline are dropped. These are always excerpts or
    string-building fragments (e.g. ``"```jac\\n" + chosen + "\\n```"`` captured
    as ``\\n" + chosen + "\\n``), never usable standalone Jac files.
  * A few ids appear on >1 record (same seed, regenerated content, differing
    only in generation_date + messages). Each colliding write is disambiguated
    with a ``__dup2``, ``__dup3``, ... suffix so nothing is overwritten.

Records with no ```jac block (e.g. documentation prose) are skipped and counted.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

JAC_BLOCK_RE = re.compile(r"```jac\b(.*?)```", re.DOTALL)


def part_suffix(i: int) -> str:
    # 0 -> "", 1 -> "__part2", 2 -> "__part3", ...
    return "" if i == 0 else f"__part{i + 1}"


def is_fragment(code: str) -> bool:
    """True if the block is not a usable standalone Jac file."""
    return "\n" not in code.strip()


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("jsonl", type=Path, help="input golden_client.jsonl")
    ap.add_argument(
        "-o", "--out", type=Path, default=Path("data/golden_client_jac"),
        help="output directory (default: data/golden_client_jac)",
    )
    ap.add_argument(
        "--keep-fragments", action="store_true",
        help="keep single-line fragment blocks (default: drop them)",
    )
    ap.add_argument(
        "--clear", action="store_true",
        help="remove <out> before writing (default: error if non-empty)",
    )
    args = ap.parse_args()

    if args.out.exists() and any(args.out.iterdir()):
        if args.clear:
            for p in args.out.iterdir():
                p.unlink()
        else:
            raise SystemExit(f"{args.out} is non-empty — pass --clear to wipe it first")

    args.out.mkdir(parents=True, exist_ok=True)

    n_records = 0
    n_with_jac = 0
    n_skipped = 0
    n_blocks = 0
    n_dropped_fragments = 0
    n_collisions = 0
    blocks_per_record: dict[int, int] = {}

    with args.jsonl.open() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            obj = json.loads(line)
            n_records += 1
            rid = obj["id"]

            content = "\n".join(
                m.get("content", "")
                for m in obj.get("messages", [])
                if m.get("role") == "assistant"
            )
            blocks = [b.strip() + "\n" for b in JAC_BLOCK_RE.findall(content)]

            if not blocks:
                n_skipped += 1
                continue

            kept = []
            for code in blocks:
                if not args.keep_fragments and is_fragment(code):
                    n_dropped_fragments += 1
                    continue
                kept.append(code)

            if not kept:
                # record had only fragment blocks
                continue

            n_with_jac += 1
            n_blocks += len(kept)
            blocks_per_record[len(kept)] = blocks_per_record.get(len(kept), 0) + 1

            for i, code in enumerate(kept):
                base = args.out / f"{rid}{part_suffix(i)}.jac"
                dest = base
                if dest.exists():
                    n_collisions += 1
                    k = 2
                    while dest.exists():
                        dest = args.out / f"{rid}{part_suffix(i)}__dup{k}.jac"
                        k += 1
                dest.write_text(code)

    print(f"records scanned         : {n_records}")
    print(f"records with >=1 block  : {n_with_jac}")
    print(f"records skipped (no jac): {n_skipped}")
    print(f"fragment blocks dropped : {n_dropped_fragments}")
    print(f"filename collisions     : {n_collisions}  (disambiguated with __dupN)")
    print(f"total .jac files written: {n_blocks}")
    print(f"output dir              : {args.out}")
    print("kept-blocks-per-record distribution:")
    for k in sorted(blocks_per_record):
        print(f"   {k} block(s): {blocks_per_record[k]} record(s)")


if __name__ == "__main__":
    main()
