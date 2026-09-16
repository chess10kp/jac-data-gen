#!/usr/bin/env python3
"""Focused tests for scripts/build_function_eval.py."""
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from scripts.eval import build_function_eval as builder


class AstClusterTests(unittest.TestCase):
    def test_alpha_renamed_locals_share_cluster(self) -> None:
        left = "def total(items):\n    out = 0\n    for item in items:\n        out += item\n    return out\n"
        right = "def sum_values(values):\n    result = 0\n    for value in values:\n        result += value\n    return result\n"
        self.assertEqual(
            builder.ast_shape_fingerprint(left),
            builder.ast_shape_fingerprint(right),
        )

    def test_literal_variants_share_cluster(self) -> None:
        left = "def above(x):\n    return x > 10\n"
        right = "def above_limit(value):\n    return value > 99\n"
        self.assertEqual(
            builder.ast_shape_fingerprint(left),
            builder.ast_shape_fingerprint(right),
        )

    def test_global_api_names_remain_distinct(self) -> None:
        minimum = "def pick(xs):\n    return min(xs)\n"
        maximum = "def pick(xs):\n    return max(xs)\n"
        self.assertNotEqual(
            builder.ast_shape_fingerprint(minimum),
            builder.ast_shape_fingerprint(maximum),
        )

    def test_docstrings_do_not_change_cluster(self) -> None:
        documented = 'def double(x):\n    """Double x."""\n    return x * 2\n'
        plain = "def twice(value):\n    return value * 7\n"
        self.assertEqual(
            builder.ast_shape_fingerprint(documented),
            builder.ast_shape_fingerprint(plain),
        )


class CompletionTests(unittest.TestCase):
    def test_prefix_and_continuation_reconstruct_reference(self) -> None:
        source = (
            "glob OFFSET = 1;\n\n"
            "def transform(value: int) -> int {\n"
            "    shifted = value + OFFSET;\n"
            "    doubled = shifted * 2;\n"
            "    return doubled;\n"
            "}\n"
        )
        prefix, continuation = builder.split_completion(source, "transform", 0.30)
        self.assertEqual(prefix + continuation, source)
        self.assertIn("shifted =", prefix)
        self.assertNotIn("doubled =", prefix)
        self.assertTrue(continuation.rstrip().endswith("}"))

    def test_single_line_body_is_fully_hidden(self) -> None:
        source = "def double(value: int) -> int { return value * 2; }"
        prefix, continuation = builder.split_completion(source, "double")
        self.assertEqual(prefix, "def double(value: int) -> int {")
        self.assertEqual(prefix + continuation, source)

    def test_missing_entrypoint_is_rejected(self) -> None:
        with self.assertRaises(ValueError):
            builder.split_completion("def other() { return; }", "wanted")


class OutputTests(unittest.TestCase):
    def test_public_tasks_never_contain_hidden_tests_or_references(self) -> None:
        source = {
            "id": 42,
            "entrypoint": "double",
            "content": "def double(x):\n    return x * 2\n",
        }
        composer = {
            "id": 42,
            "source": "idiomatic",
            "jac": "def double(x: int) -> int { return x * 2; }",
        }
        artifact = {
            "floor_fn": "def double(x: Any) -> object { return x * 2; }",
            "test_blocks": 'test "t0" { assert double(2) == 4; }',
        }
        public, private = builder.make_tasks(
            42, "dev", "abc", source, composer, artifact
        )
        serialized_public = json.dumps(public)
        self.assertNotIn("test_blocks", serialized_public)
        self.assertNotIn("floor_jac", serialized_public)
        self.assertNotIn("idiomatic_jac", serialized_public)
        self.assertEqual(len(public), 2)
        self.assertEqual(len(private), 2)
        self.assertIn("test_blocks", private[0])

    def test_composer_snapshot_rejects_duplicate_ids(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "composer.jsonl"
            row = {"id": 1, "jac": "def f() { return; }"}
            path.write_text(json.dumps(row) + "\n" + json.dumps(row) + "\n")
            with self.assertRaises(ValueError):
                builder.load_composer_snapshot(path)

    def test_loads_reference_failure_exclusions(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "failed.txt"
            path.write_text("7\n2\n7\n")
            self.assertEqual(builder.load_id_file(path), {2, 7})


if __name__ == "__main__":
    unittest.main()
