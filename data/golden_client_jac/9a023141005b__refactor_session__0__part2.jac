"""Graph-shaped EVAL holdout — disjoint task types, behavioral test cases.

Companion to graph_seeds.jac. These 6 tasks are DIFFERENT aggregations than the 8
training tasks (min/odd/sum-above/branches/range/negative vs count/sum/max/...), so
scoring measures generalization of graph idiom, not memorization. Same schema as the
function holdout (func_name, python, prompt, test_cases, source) so eval_probe.jac /
idiom_eval.jac drive it via JAC_HOLDOUT=01-sft-dpo/dataset/eval_holdout/graph_conversion.jsonl.

    jac run 01-sft-dpo/sft_dpo/jacgen/graph_holdout.jac
"""

import json;
import from pathlib { Path }
import from typing { Any }

glob TASKS: str = "01-sft-dpo/sft_dpo/jacgen/graph_data/holdout.json";
glob OUT_PATH: str = "01-sft-dpo/dataset/eval_holdout/graph_conversion.jsonl";
glob SOURCE: str = "generated_graph_holdout";


def make_prompt(python_code: str) -> str {
    return "Convert this Python to idiomatic Jac:\n\n
