"""GRPO reward logic, in Jac: the verifiable `jac run` gate as a reward function.

All reward logic lives here. `02-rl-grpo/rl/reward.py` is a 2-line shim that imports this
module so `mlx_lm_lora`'s Python loader (`spec_from_file_location`, which needs a
`.py`) triggers the registration below. For each sampled completion: splice it
into the task template (`__HOLE__`), run it with `jac` (isolated cwd so the
persistent `root` graph never accumulates), and score MONOTONICALLY by tier:

    exact stdout match          -> 1.0                 (the only way to score 1.0)
    runs, wrong stdout          -> 0.40 + 0.25*line_frac + 0.15*sim   (<= 0.80)
    compiles, doesn't run       -> 0.20 + 0.15*sim                    (<= 0.35)
    neither                     -> 0.15*sim                           (<= 0.15)

`sim` (difflib ratio to the stripped gold body) is present in EVERY tier including
non-compiling, so a group of all-failing rollouts still has within-group variance
-> non-zero GRPO advantage (breaks the sigma=0 cold-start trap). Each tier's ceiling
is strictly below the next tier's floor, so reward is monotone with the headline:
an exact pass always beats any non-exact completion (the old additive formula let a
wrong-output completion with high idiom/sim outscore a correct terse one).

The idiom term was REMOVED from the reward: it is trivially gamed (stuff `-->`
tokens), anti-correlates with terse gold bodies, and the headline metric never
rewards idioms. `idiom_bonus`/eval still REPORT idiom density as a descriptive stat.
Mirrors 01-sft-dpo/sft_dpo/jacgen/writer.jac:run_jac.
"""

import os;
import re;
import json;
import difflib;
import subprocess;
import tempfile;
import from functools { lru_cache }
import from pathlib { Path }
import from mlx_lm_lora.trainer.grpo_reward_functions { register_reward_function }

glob ROOT: str = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))));
glob TEMPLATES: str = os.path.join(ROOT, "02-rl-grpo", "dataset", "rl", "templates");
glob REFBODIES: str = os.path.join(ROOT, "02-rl-grpo", "dataset", "rl", "refbodies");
glob JAC: str = os.path.join(ROOT, ".venv", "bin", "jac") if os.path.exists(os.path.join(ROOT, ".venv", "bin", "jac")) else "jac";

# Weighted idiom markers: graph-traversal/object-spatial ops (the hard, distinctly
# Jac constructs) count for more than plain declarations. Rewards genuinely
# graph-spatial bodies over function-shaped ones.
glob IDIOM_WEIGHTS: dict[str, int] = {
    "visit ": 3, "-->": 3, "<--": 3, "++>": 3, "<++": 3, "spawn": 3, "disengage": 3,
    "report ": 2, " here": 2, " root": 2, "walker ": 2, "node ": 2, "edge ": 2,
    "with entry": 1, "with exit": 1, "can ": 1, " obj ": 1, "has ": 1
};

def unwrap_unit(body: str) -> str {
    # Fallback: inner block of a single wrapped unit; bare bodies untouched.
    s = body.strip();
    if re.match(r"^(can|def|walker|node|obj|edge|with)\b", s) and "{" in s and "}" in s {
        return s[s.index("{") + 1 : s.rindex("}")].strip();
    }
    return s;
}

def hole_unit_name(template: str) -> str {
    m = re.search(r"(?:def|can|walker|node|obj|edge)\s+(\w+)\b[^{]*\{\s*__HOLE__", template);
    return str(m.group(1)) if m else "";
}

def unit_body(code: str, name: str) -> str {
    # Brace-match the body of unit `name` out of `code` (may be the whole echoed
    # driver). "" if not found. Models reproduce the full driver, so we must pull
    # THIS unit's body — blindly unwrapping the first/last brace grabbed the
    # docstring and corrupted the reward (~4x undercount) as well as the eval.
    if not name {
        return "";
    }
    m = re.search(r"(?:def|can|walker|node|obj|edge)\s+" + re.escape(name) + r"\b[^{]*\{", code);
    if not m {
        return "";
    }
    start = m.end() - 1;
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

def extract_jac(completion: str, template: str = "") -> str {
    code = completion;
    if "
