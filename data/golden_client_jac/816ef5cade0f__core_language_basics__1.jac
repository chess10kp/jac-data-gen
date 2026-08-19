"""studio - dataset stats / preview / ingest. Ports server/datasets.py.

Read-only browser (stats/files/rows) + append. Builder pipeline (subprocess)
lands with the jobs module. All code fields returned as raw strings.
"""

import os;
import json;
import re;
import models;
import from pathlib { Path }

# RL data lives in THIS repo (jac_ml_studio), not the studio's data_root (which points
# at the DataGeneration checkout). Resolve RL files against the repo root, like rl.sv.jac.
# studio/ sits directly at repo root (post Jul-10 flatten) → two dirnames up.
glob RL_ROOT: str = os.path.dirname(os.path.dirname(os.path.abspath(__file__)));

glob PREVIEW_FILES: list[list[str]] = [
    ["model-experiments/01-sft-dpo/dataset/conversion/sft.jsonl", "SFT idiomatic core"],
    ["model-experiments/01-sft-dpo/dataset/conversion/sft_auto.jsonl", "SFT transpile volume"],
    ["model-experiments/01-sft-dpo/dataset/conversion/dpo.jsonl", "DPO pairs"],
    ["model-experiments/01-sft-dpo/dataset/mlx/train.jsonl", "MLX SFT train"],
    ["model-experiments/01-sft-dpo/dataset/mlx/valid.jsonl", "MLX SFT valid"],
    ["model-experiments/01-sft-dpo/dataset/mlx_dpo/train.jsonl", "MLX DPO train"],
    ["model-experiments/01-sft-dpo/dataset/mlx_dpo/valid.jsonl", "MLX DPO valid"],
    ["model-experiments/01-sft-dpo/dataset/eval_holdout/conversion.jsonl", "Holdout (function)"],
    ["model-experiments/01-sft-dpo/dataset/eval_holdout/graph_conversion.jsonl", "Holdout (graph)"]
];
glob APPEND_TARGETS: dict = {
    "sft": "model-experiments/01-sft-dpo/dataset/conversion/sft.jsonl", "dpo": "model-experiments/01-sft-dpo/dataset/conversion/dpo.jsonl"
};

# RL data pipeline — grouped by training use. SFT=gold {messages}; the rest are the
# {prompt, answer} task pool (GRPO reward / eval). See RL_FINDINGS.md.
glob RL_SOURCES: list[str] = ["SFT", "GRPO", "conversion", "synthetic", "splits"];
glob RL_PREVIEW_FILES: dict = {
    "SFT": [["model-experiments/02-rl-grpo/dataset/rl/rft/train.jsonl", "RFT gold · train"], ["model-experiments/02-rl-grpo/dataset/rl/rft/valid.jsonl", "RFT gold · valid"]],
    "GRPO": [["model-experiments/02-rl-grpo/dataset/rl/tasks.jsonl", "reward tasks · all"], ["model-experiments/02-rl-grpo/dataset/rl/train.jsonl", "GRPO train pool"], ["model-experiments/02-rl-grpo/dataset/rl/valid.jsonl", "GRPO valid"]],
    "conversion": [["model-experiments/02-rl-grpo/dataset/rl_conv/tasks.jsonl", "python→jac · all"], ["model-experiments/02-rl-grpo/dataset/rl_conv/train.jsonl", "conv train"], ["model-experiments/02-rl-grpo/dataset/rl_conv/holdout.jsonl", "conv holdout"]],
    "synthetic": [["model-experiments/02-rl-grpo/dataset/rl/synthetic.jsonl", "synthetic · fresh (32)"]],
    "splits": [["model-experiments/02-rl-grpo/dataset/rl/holdout.jsonl", "holdout n=18"], ["model-experiments/02-rl-grpo/dataset/rl/holdout_big.jsonl", "holdout n=32 (+syn)"], ["model-experiments/02-rl-grpo/dataset/rl/train_big.jsonl", "train pool (+syn)"]]
};

obj FileRefView {
    has path: str = "", label: str = "", count: int = 0;
}

obj DataRowView {
    has idx: int = 0, name: str = "", difficulty: str = "", source: str = "",
        kind: str = "", preview: str = "", prompt: str = "", python: str = "",
        jac: str = "", chosen: str = "", rejected: str = "", raw: str = "";
}

def _abs(rel: str) -> Path {
    return models.data_root() / rel;
}

def _allowed(rel: str) -> bool {
    for pair in PREVIEW_FILES {
        if pair[0] == rel {
            return True;
        }
    }
    return False;
}

def _read_lines(rel: str) -> list {
    p = _abs(rel);
    if not p.exists() {
        return [];
    }
    nl = "\n";
    out: list = [];
    for line in p.read_text().split(nl) {
        if line.strip() {
            out.append(line);
        }
    }
    return out;
}

def _line_count(rel: str) -> int {
    return len(_read_lines(rel));
}

def _fence(text: str, lang: str) -> str {
    m = re.search("(?s)
