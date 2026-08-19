"""studio - model registry + data-root resolution.

Ports server/config.py. models/ is gitignored and resolves against
JAC_STUDIO_DATA_ROOT (the main checkout). `list_models` is the client-facing
endpoint; the rest are helpers used by chat/eval/train modules.
"""

import os;
import inference;
import from pathlib { Path }

glob DEFAULT_ROOT: str = "/Volumes/ExtremePro/JaseciLabs/jac_model_studio";

glob MODELS: list[dict] = [
    {"id": "qwen2-dpo", "label": "Qwen2 · DPO", "path": "models/qwen2-jac-dpo-fused-q8"},
    {"id": "qwen2-sft", "label": "Qwen2 · SFT", "path": "models/qwen2-jac-fused-q8"}
];

# Eval holdout sets (rel to data root) + run dirs that are NOT training runs.
glob HOLDOUTS: dict = {
    "function": "model-experiments/01-sft-dpo/dataset/eval_holdout/conversion.jsonl",
    "graph": "model-experiments/01-sft-dpo/dataset/eval_holdout/graph_conversion.jsonl"
};
glob EXCLUDED_RUN_DIRS: list[str] = ["comparison", "_builder", "_evals"];

"""One model as the client sees it: registry entry + on-disk availability."""
obj ModelView {
    has id: str = "",
        label: str = "",
        path: str = "",
        available: bool = False,
        size_gb: float = 0.0;
}

def data_root() -> Path {
    return Path(os.environ.get("JAC_STUDIO_DATA_ROOT", DEFAULT_ROOT));
}

def model_by_id(model_id: str) -> dict {
    for m in MODELS {
        if m["id"] == model_id {
            return m;
        }
    }
    return {};
}

def model_path(m: dict) -> Path {
    return data_root() / str(m["path"]);
}

def model_available(m: dict) -> bool {
    return model_path(m).is_dir();
}

def results_dir() -> Path {
    # run_probe.sh / run_dpo.sh cd to the repo root and write under
    # model-experiments/01-sft-dpo/results/, so the studio must read the same tree.
    return data_root() / "model-experiments/01-sft-dpo" / "results";
}

def jac_bin() -> Path {
    return data_root() / ".venv" / "bin" / "jac";
}

glob _size_cache: dict = {};

"""On-disk size of a model dir in GB (2 dp). round(x,2) is broken in the checker,
so the cents are computed with int division instead. Memoized per path — model
dirs are static multi-GB trees and every list_models call was rglob-stat'ing
thousands of files (sluggish Chat/Evals mounts); restart refreshes the cache."""
def dir_size_gb(p: Path) -> float {
    if not p.is_dir() { return 0.0; }
    key = str(p);
    if key in _size_cache { return float(str(_size_cache[key])); }
    total = 0;
    for f in p.rglob("*") {
        if f.is_file() { total += f.stat().st_size; }
    }
    gb = int(total / 10_000_000) / 100.0;
    _size_cache[key] = gb;
    return gb;
}

def total_ram_gb() -> int {
    return round(os.sysconf("SC_PHYS_PAGES") * os.sysconf("SC_PAGE_SIZE") / 1024 ** 3);
}

"""Total system RAM in GB — the sidebar memory gauge."""
def:pub system_ram() -> int {
    return total_ram_gb();
}

"""The model registry with live on-disk availability + size — the chat model picker."""
def:pub list_models() -> list[ModelView] {
    out: list[ModelView] = [];
    for m in MODELS {
        avail = model_available(m);
        out.append(
            ModelView(
                id=str(m["id"]),
                label=str(m["label"]),
                path=str(m["path"]),
                available=avail,
                size_gb=dir_size_gb(model_path(m)) if avail else 0.0
            )
        );
    }
    return out;
}

"""The currently-resident model: {id, resident_gb}. Drives the model-pill LOADED
badge and the sidebar MEM gauge. Empty id + 0.0 when nothing is loaded."""
def:pub loaded_model() -> dict {
    return inference.loaded_info();
}

"""Eagerly load (warm) a model so the next completion streams immediately. Blocks
until resident; the client shows elapsed via its own timer. Returns
{id, load_s, error} — error is "" on success, a message otherwise."""
def:pub warm_model(model_id: str) -> dict {
    m = model_by_id(model_id);
    if not m {
        return {"id": model_id, "load_s": 0.0, "error": f"unknown model_id: {model_id}"};
    }
    if not model_available(m) {
        return {"id": model_id, "load_s": 0.0, "error": f"model not found on disk: {model_id}"};
    }
    s = inference.load_sync(model_id, str(model_path(m)));
    return {"id": model_id, "load_s": s, "error": ""};
}
