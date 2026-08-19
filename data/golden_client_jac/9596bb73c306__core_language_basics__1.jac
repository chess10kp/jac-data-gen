"""Persist and re-validate generated Jac conversion examples.

Generation itself is agentic (Claude + jac-mcp). This module only persists the
results and re-runs them through the Jac compiler/runtime so every stored line
is provably compiler-clean and behaviorally correct.
"""

import json;
import subprocess;
import tempfile;
import from pathlib { Path }


def make_sft_example(python_code: str, jac_code: str, difficulty: str,
                     expected_output: str, source: str = "generated_seed",
                     generator: str = "claude-code-mcp") -> dict {
    user: str = "Convert this Python to idiomatic Jac:\n\n
