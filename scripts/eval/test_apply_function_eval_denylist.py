#!/usr/bin/env python3
"""Tests for scripts/apply_function_eval_denylist.py."""
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from scripts.eval import apply_function_eval_denylist as guard


class DenylistTests(unittest.TestCase):
    def make_eval(self, root: Path, status: str = "sealed") -> None:
        deny = root / "denylist_ids.txt"
        deny.write_text("2\n7\n")
        manifest = {
            "status": status,
            "files": {
                "denylist_ids.txt": {
                    "sha256": guard.sha256_file(deny),
                    "bytes": deny.stat().st_size,
                }
            },
            "counts": {"reserved_clusters": 2},
            "composer_snapshot": {"sha256": "snapshot"},
        }
        (root / "manifest.json").write_text(json.dumps(manifest))

    def test_unsealed_eval_is_rejected_by_default(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_eval(root, "candidate_unvalidated")
            with self.assertRaisesRegex(ValueError, "requires a sealed eval"):
                guard.load_denylist(root, False)
            denied, _ = guard.load_denylist(root, True)
            self.assertEqual(denied, {2, 7})

    def test_hash_mismatch_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_eval(root)
            (root / "denylist_ids.txt").write_text("999\n")
            with self.assertRaisesRegex(ValueError, "hash"):
                guard.load_denylist(root, False)

    def test_filter_removes_denied_ids(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            input_path = root / "input.jsonl"
            output_path = root / "output.jsonl"
            input_path.write_text(
                "".join(
                    json.dumps(row) + "\n"
                    for row in ({"id": 1}, {"id": 2}, {"source_id": 7}, {"id": 8})
                )
            )
            counts = guard.scan_or_filter(input_path, {2, 7}, output_path)
            self.assertEqual(counts["input_rows"], 4)
            self.assertEqual(counts["kept_rows"], 2)
            self.assertEqual(counts["denied_rows"], 2)
            kept = [json.loads(line) for line in output_path.read_text().splitlines()]
            self.assertEqual(kept, [{"id": 1}, {"id": 8}])

    def test_filter_refuses_overwrite(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            input_path = root / "input.jsonl"
            output_path = root / "output.jsonl"
            input_path.write_text('{"id": 1}\n')
            output_path.write_text("existing")
            with self.assertRaises(FileExistsError):
                guard.scan_or_filter(input_path, set(), output_path)


if __name__ == "__main__":
    unittest.main()
