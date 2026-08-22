#!/usr/bin/env python3
"""Focused unit tests for scripts/eval_jac.py."""
from __future__ import annotations

import unittest

from scripts import eval_jac


class ExtractionTests(unittest.TestCase):
    def test_extracts_one_jac_fence(self) -> None:
        source, error = eval_jac.extract_jac("before\n```jac\ndef f() { return; }\n```\nafter")
        self.assertIsNone(error)
        self.assertEqual(source, "def f() { return; }")

    def test_rejects_multiple_jac_fences(self) -> None:
        source, error = eval_jac.extract_jac("```jac\na;\n```\n```jac\nb;\n```")
        self.assertIsNone(source)
        self.assertIn("found 2", error or "")

    def test_assembles_completion(self) -> None:
        source, error = eval_jac.assemble_source(
            {"prefix": "def f() {\n", "suffix": "\n}"},
            {"completion": "return;"},
        )
        self.assertIsNone(error)
        self.assertEqual(source, "def f() {\nreturn;\n}")


class StaticContractTests(unittest.TestCase):
    def test_osp_constructs_are_detected(self) -> None:
        source = """node Person { has name: str; }
walker:pub greet {
    can run with Root entry {
        people = [-->[?:Person]];
        visit people;
        report people;
    }
}
"""
        flags = eval_jac.feature_flags(source)
        self.assertTrue(flags["node"])
        self.assertTrue(flags["walker"])
        self.assertTrue(flags["ability_entry"])
        self.assertTrue(flags["graph_reference"])
        self.assertTrue(flags["visit"])
        self.assertTrue(flags["report"])
        self.assertTrue(flags["typed_has"])

    def test_match_is_not_an_idiomaticity_signal(self) -> None:
        flags = eval_jac.feature_flags("match value { case 1: return True; }")
        self.assertNotIn("match", flags)

    def test_object_and_any_are_dynamic_type_smells(self) -> None:
        diagnostics = eval_jac.static_diagnostics(
            "def f(x: Any) -> object { return x; }"
        )
        self.assertEqual(diagnostics["dynamic_type_mentions"], 2)
        self.assertFalse(diagnostics["features"]["no_dynamic_types"])

    def test_postgres_startup_failure_is_infrastructure(self) -> None:
        result = eval_jac.ProcessResult(
            2,
            "",
            "embedded postgres unreachable; postgres not ready after 60.0s",
            1.0,
        )
        self.assertTrue(eval_jac.is_infra_failure(result))

    def test_transpiler_residue_is_reported_without_style_score(self) -> None:
        diagnostics = eval_jac.static_diagnostics(
            "def copy(xs: list[int]) -> list[int] {\n"
            "    for i in range(len(xs)) { print(xs[i]); }\n"
            "    return xs;\n}"
        )
        self.assertEqual(diagnostics["range_len_loops"], 1)
        self.assertGreaterEqual(diagnostics["max_brace_depth"], 2)
        self.assertNotIn("idiomaticity_score", diagnostics)

    def test_required_features_are_problem_specific(self) -> None:
        problem = {"id": "osp-1", "required_features": ["node", "walker"]}
        flags = {name: False for name in eval_jac.FEATURE_PATTERNS}
        flags["node"] = True
        passed, missing, forbidden = eval_jac.validate_contract(problem, flags)
        self.assertFalse(passed)
        self.assertEqual(missing, ["walker"])
        self.assertEqual(forbidden, [])


class MetricsTests(unittest.TestCase):
    def test_pass_at_one_is_sample_accuracy(self) -> None:
        self.assertEqual(eval_jac.pass_at_k(4, 2, 1), 0.5)

    def test_pass_at_k_saturates_when_fewer_than_k_fail(self) -> None:
        self.assertEqual(eval_jac.pass_at_k(5, 4, 2), 1.0)

    def test_failed_samples_remain_in_pass_at_k_denominator(self) -> None:
        rows = [
            {
                "problem_id": "p1",
                "track": "function",
                "status": "pass",
                "check_pass": True,
                "has_behavior_tests": True,
                "test_pass": True,
                "task_success": True,
                "contract_pass": True,
                "static": {"features": {}},
            },
            {
                "problem_id": "p1",
                "track": "function",
                "status": "check_fail",
                "check_pass": False,
                "has_behavior_tests": True,
                "test_pass": False,
                "task_success": False,
                "contract_pass": False,
                "static": {"features": {}},
            },
        ]
        summary = eval_jac.aggregate(rows, [1])
        self.assertEqual(summary["check_rate"], 0.5)
        self.assertEqual(summary["behavior_test_rate"], 0.5)
        self.assertEqual(summary["task_success_rate"], 0.5)
        self.assertEqual(summary["pass_at_k"]["1"]["value"], 0.5)
        self.assertIn("typing", summary["static_diagnostics"])
        self.assertEqual(summary["static_diagnostics"]["note"], "reported independently; no aggregate idiomaticity score")

    def test_compile_only_rows_do_not_enter_pass_at_k(self) -> None:
        rows = [
            {
                "problem_id": "osp-compile",
                "track": "osp",
                "status": "check_pass",
                "check_pass": True,
                "has_behavior_tests": False,
                "test_pass": None,
                "task_success": None,
                "contract_pass": True,
                "static": {"features": {"node": True}},
            }
        ]
        summary = eval_jac.aggregate(rows, [1])
        self.assertIsNone(summary["task_success_rate"])
        self.assertIsNone(summary["pass_at_k"]["1"]["value"])
        self.assertEqual(summary["compile_only_samples"], 1)


if __name__ == "__main__":
    unittest.main()
