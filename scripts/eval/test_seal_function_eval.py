#!/usr/bin/env python3
"""Focused tests for scripts/seal_function_eval.py."""
from __future__ import annotations

import json
import os
import tempfile
import unittest
from pathlib import Path

from scripts.eval import build_function_eval as builder
from scripts.eval import seal_function_eval as sealer


class SealIntegrityTests(unittest.TestCase):
    def make_eval(self, root: Path) -> dict:
        (root / "public").mkdir(parents=True)
        (root / "private").mkdir()
        source = {
            "id": 7,
            "entrypoint": "double",
            "content": "def double(x):\n    return x * 2\n",
        }
        composer = {
            "id": 7,
            "source": "idiomatic",
            "jac": "def double(x: int) -> int { return x * 2; }",
        }
        artifact = {
            "floor_fn": "def double(x: Any) -> object { return x * 2; }",
            "test_blocks": 'test "t0" { assert double(2) == 4; }',
        }
        public, private = builder.make_tasks(
            7, "dev", "cluster", source, composer, artifact
        )
        builder.write_jsonl(root / "public" / "dev.jsonl", public)
        builder.write_jsonl(root / "private" / "dev.jsonl", private)
        manifest = {
            "status": "candidate_unvalidated",
            "composer_snapshot": {"sha256": "abc"},
            "files": builder.file_manifest(root),
        }
        (root / "manifest.json").write_text(json.dumps(manifest))
        return manifest

    def test_manifest_hashes_and_task_pairs_validate(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest = self.make_eval(root)
            sealer.verify_manifest_files(root, manifest)
            rows, references = sealer.load_and_verify_tasks(root, ["dev"])
            self.assertEqual(len(rows), 2)
            self.assertEqual(set(references), {7})

    def test_file_mutation_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest = self.make_eval(root)
            with (root / "public" / "dev.jsonl").open("a") as handle:
                handle.write("{}\n")
            with self.assertRaisesRegex(ValueError, "hash mismatch"):
                sealer.verify_manifest_files(root, manifest)

    def test_public_private_id_mismatch_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_eval(root)
            rows = sealer.read_jsonl(root / "public" / "dev.jsonl")
            rows.pop()
            builder.write_jsonl(root / "public" / "dev.jsonl", rows)
            with self.assertRaisesRegex(ValueError, "ID mismatch"):
                sealer.load_and_verify_tasks(root, ["dev"])

    def test_passing_batch_marks_every_reference_passed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            fake_jac = root / "jac"
            fake_jac.write_text("#!/bin/sh\nexit 0\n")
            os.chmod(fake_jac, 0o755)
            problem = {
                "id": "fn-translate-1",
                "track": "function",
                "idiomatic_jac": "def f(x: int) -> int { return x; }",
                "test_blocks": 'test "t" { assert f(1) == 1; }',
                "required_features": ["no_python_syntax", "no_test_blocks"],
                "forbidden_features": ["node", "edge", "walker"],
            }
            references = [(1, problem), (2, {**problem, "id": "fn-translate-2"})]
            results = sealer.validate_reference_batches(
                references,
                jac_bin=str(fake_jac),
                batch_size=2,
                batch_timeout_s=5,
                fallback_timeout_s=5,
                tmp_root=None,
                jac_tmp=None,
            )
            self.assertEqual([row["status"] for row in results], ["pass", "pass"])
            self.assertTrue(all(row["task_success"] for row in results))


if __name__ == "__main__":
    unittest.main()
