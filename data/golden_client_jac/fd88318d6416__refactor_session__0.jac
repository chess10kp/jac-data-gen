"""Score a model on the RL holdout (02-rl-grpo/dataset/rl/holdout.jsonl).

Loads the MLX model ONCE (eval_probe.jac pattern), generates a completion per
held-out task, splices it into the task template, runs it isolated (`jac run`,
cwd=tmp so the persistent root graph never accumulates), and reports
run% / behavior-pass% / avg idiom-construct count. Pass the GRPO adapter via
JAC_EVAL_ADAPTER to measure the post-RL model; omit it for the base.

  JAC_EVAL_MODEL=models/qwen-q4 JAC_EVAL_ADAPTER=02-rl-grpo/adapters/qwen3-grpo jac run 02-rl-grpo/rl/eval_rl.jac

Env: JAC_EVAL_MODEL (required), JAC_EVAL_ADAPTER (""), JAC_RL_HOLDOUT
     (02-rl-grpo/dataset/rl/holdout.jsonl), JAC_RL_OUT (append a metrics JSON line),
     JAC_EVAL_LIMIT (0=all). Lazy-imports mlx_lm -> parse-check only (-p).
"""

import os;
import re;
import json;
import difflib;
import tempfile;
import subprocess;
import from pathlib { Path }

glob IDIOM_MARKERS: list[str] = [
    "walker ", "node ", "edge ", "with entry", "with exit", "can ",
    "visit ", "spawn", "disengage", "-->", "<--", "++>", "<++",
    " obj ", "has ", "report ", " root", " here"
];

def load_model(mp: str, adapter: str) -> tuple;

def gen_mlx(model: any, tok: any, prompt: str) -> str {
    import mlx_lm;
    msgs = [{"role": "user", "content": prompt}];
    text = tok.apply_chat_template(msgs, add_generation_prompt=True, tokenize=False);
    out = "";
    for resp in mlx_lm.stream_generate(model, tok, text, max_tokens=512) {
        out += resp.text;
    }
    return out;
}

def gen_mlx_sampled(model: any, tok: any, prompt: str, temp: float) -> str {
    # Temperature-sampled generation for pass@k (greedy can't show RL distribution
    # shifts; sampled reveals whether ANY of k tries passes).
    import mlx_lm;
    import from mlx_lm.sample_utils { make_sampler }
    msgs = [{"role": "user", "content": prompt}];
    text = tok.apply_chat_template(msgs, add_generation_prompt=True, tokenize=False);
    sampler = make_sampler(temp=temp);
    out = "";
    for resp in mlx_lm.stream_generate(model, tok, text, max_tokens=512, sampler=sampler) {
        out += resp.text;
    }
    return out;
}

def passes(template: str, gen: str, expected: str, timeout: int) -> bool {
    body = extract_jac(gen, template);
    (code, out, err) = run_jac(template.replace("__HOLE__", body), timeout);
    return code == 0 and out.strip() == expected.strip();
}

def unwrap_unit(body: str) -> str {
    # Fallback: return the inner block when the completion is one wrapped unit.
    s = body.strip();
    if re.match(r"^(can|def|walker|node|obj|edge|with)\b", s) and "{" in s and "}" in s {
        return s[s.index("{") + 1 : s.rindex("}")].strip();
    }
    return s;
}

def hole_unit_name(template: str) -> str {
    # Name of the unit whose body is the __HOLE__ (e.g. `def _one_dp(..) { __HOLE__ }`).
    m = re.search(r"(?:def|can|walker|node|obj|edge)\s+(\w+)\b[^{]*\{\s*__HOLE__", template);
    return str(m.group(1)) if m else "";
}

def unit_body(code: str, name: str) -> str {
    # Brace-match the body of unit `name` out of `code` (which may be the whole
    # echoed driver). Returns "" if not found. This is the real extractor: the model
    # reproduces the entire driver, so we must pull THIS unit's body, not blindly
    # unwrap the first/last brace pair (which grabbed the docstring -> ~4x undercount).
    if not name {
        return "";
    }
    m = re.search(r"(?:def|can|walker|node|obj|edge)\s+" + re.escape(name) + r"\b[^{]*\{", code);
    if not m {
        return "";
    }
    start = m.end() - 1;   # index of the opening {
    depth = 0; i = start;
    while i < len(code) {
        ch = code[i];
        if ch == "{" { depth += 1; }
        elif ch == "}" {
            depth -= 1;
            if depth == 0 {
                return code[start + 1 : i].strip();
            }
        }
        i += 1;
    }
    return "";
}

def extract_jac(output: str, template: str) -> str {
    # code fence -> jac block; else whole output
    code = output;
    if "
