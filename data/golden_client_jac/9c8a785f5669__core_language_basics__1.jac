"""Idiom-quality judge: split a model's correct Jac into idiomatic vs Python-shaped.

The behavioral probe (eval_probe.jac) answers "does the Jac run and match outputs?"
It does NOT answer "is the Jac idiomatic, or just Python-shaped Jac that happens to
run?" — which matters because the training mix is 1:3 idiom:transpile, so a model can
score high on behavior by learning to transpile.

This judge measures idiom two ways, per holdout task, with NO extra model:
  1. divergence-from-transpile: rouge_l(model_output, py2jac(python)). The mechanical
     transpile IS the Python-shaped baseline. HIGH similarity => the model reproduced
     the transpile (Python-shaped). LOW similarity + still runs => it rewrote the code
     into something different/cleaner (idiomatic-divergent).
  2. graph-spatial construct usage: how many Jac-native constructs (walker/node/edge/
     ability/with-entry/visit/spawn/edge-ops/has-typed...) the output uses. Informational
     — simple functions legitimately need only `def` + `with entry`.

Buckets each RUNNING output as `python_shaped` (sim >= SIM_THRESH) or `idiomatic`
(sim < SIM_THRESH); non-running outputs are `broken`. Reports the split + averages.

    JAC_EVAL_MODE=mlx JAC_EVAL_MODEL=models/x JAC_EVAL_ADAPTER=01-sft-dpo/adapters/y \
        jac run srccurrent/jacgen/idiom_eval.jac

Env: JAC_EVAL_MODE (py2jac|mlx), JAC_EVAL_MODEL, JAC_EVAL_ADAPTER, JAC_EVAL_LIMIT,
     JAC_IDIOM_SIM (sim threshold, default 0.7), JAC_IDIOM_OUT (metrics jsonl).
The py2jac mode is a sanity check: it should bucket ~100% python_shaped (sim 1.0).
"""

import json;
import os;
import re;
import from corpus { transpile, sanitize_transpile }
import from writer { run_jac }
import from dedup { rouge_l }
import from pathlib { Path }
import from typing { Any }

glob HOLDOUT: str = "01-sft-dpo/dataset/eval_holdout/conversion.jsonl";

# Jac-native / graph-spatial constructs. Presence => the output leans on Jac idiom
# rather than plain imperative Python-in-Jac.
glob IDIOM_MARKERS: list[str] = [
    "walker ", "node ", "edge ", "with entry", "with exit", "can ",
    "visit ", "spawn", "disengage", "-->", "<--", "++>", "<++",
    " obj ", "has ", "glob ", "report ", " root", " here"
];


def eval_mode() -> str {
    return os.environ.get("JAC_EVAL_MODE", "py2jac");
}


def load_model(mp: str, adapter: str) -> tuple {
    import mlx_lm;   # lazy: top-level import crashes the jac type-checker on mlx types
    if adapter != "" {
        return mlx_lm.load(mp, adapter_path=adapter);  # jac:ignore[E1032]
    }
    return mlx_lm.load(mp);  # jac:ignore[E1032]
}


def gen_mlx(model: Any, tok: Any, prompt: str) -> str {
    import mlx_lm;
    msgs: list = [{"role": "user", "content": prompt}];
    ptoks = tok.apply_chat_template(msgs, add_generation_prompt=True);
    text: str = "";
    for resp in mlx_lm.stream_generate(model, tok, ptoks, max_tokens=512) {  # jac:ignore[E1053,E1032]
        text += str(resp.text);
    }
    return text;
}


def extract_jac(output: str) -> str {
    body: str = output;
    if "
