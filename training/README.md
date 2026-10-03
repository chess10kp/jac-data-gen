# QLoRA SFT pipeline — Ornith-1.5-9B on Jac translation

Trains LoRA adapters on the repo's release translation datasets, evaluated
against the frozen `evals/function/v1` suite plus a repo-level js2jac holdout.

## Hosts

- **clarity2 is the primary training box** (RTX 3090 24 GB, driver 560 /
  CUDA 12.6). Its venv pins the cu126 builds locally:
  `torch==2.13.0+cu126` plus `torchvision/torchaudio/torchcodec +cu126`
  (the locked default builds target CUDA 13 and fail on driver 560).
  Any `uv sync` reverts them — re-apply after:
  `uv pip install --python .venv/bin/python --reinstall-package torch \
    --reinstall-package torchvision --reinstall-package torchaudio \
    --reinstall-package torchcodec \
    "torch==2.13.0+cu126" "torchvision==0.28.0+cu126" \
    "torchaudio==2.11.0+cu126" "torchcodec==0.16.0+cu126" \
    --index-url https://download.pytorch.org/whl/cu126`
- clarity3 (RTX 3090 24 GB, driver 580 / CUDA 13) ran qlora-v1 end to end;
  kept as a fallback. Its cron `@reboot` auto-resume is not wired on clarity2,
  so start/resume runs manually there (`train-resume.sh`).
- Status: `ssh clarity2 '~/repos/jac_llm_data/training/train-status'`.

## Why these choices

- **Ornith-1.5-9B** (`ornith-ai/Ornith-1.5-9B`): dense 9B, Qwen3.5-family,
  MIT, needs transformers >= 5.8.1 / vLLM >= 0.19.1.
- **QLoRA** (NF4 + double quant, r=32/alpha=64, all linear projections) fits a
  single rented RTX 4090 24 GB at 4k context; paged optimizer absorbs spikes.
- **TRL + peft + bitsandbytes**, not Unsloth: the `qwen3_5` arch is upstream
  in transformers, so stock TRL works on day one; Unsloth support for new
  archs can lag. Revisit if Unsloth ships `qwen3_5` (≈2x throughput).
- **Checkpoint's own chat template** at train time (`training/chat.py` renders
  via `apply_chat_template` and asserts the generation-prompt suffix) — the
  model card warns their Qwen template is modified. Prompt/completion are
  stored unrendered in the JSONL; rendering is pinned to the downloaded
  tokenizer, so template drift is impossible.
- **Non-thinking targets**: Ornith's template renders assistant turns as
  `<think>…</think>\n\n{content}` and its default generation prompt ends
  `<|im_start|>assistant\n<think>\n`. Targets train `\n</think>\n\n` + code:
  an immediately-closed empty think block, then the answer (Qwen3 non-thinking
  recipe adapted to this template). Phase 2 idea: rejection-sample real CoT
  traces that pass the guards and retrain on those to keep reasoning alive.
- **Contamination guard**: every id in `evals/function/v1/denylist_ids.txt`
  (AST-cluster siblings of eval problems) is rejected at build time.
- **Honest splits**: python family holds out 2% of unique source ids; js2jac
  holds out whole GitHub repos (never per row). NB: repo-level splitting is
  necessary but not sufficient — 71 js bodies appear verbatim in more than one
  repo, and the corpus is shadcn-fork-heavy, so near-duplicates cross the split.

## Spectrum runs (Spectrum-25 + QLoRA)

arXiv 2406.06623 picks LoRA targets by signal-to-noise ratio instead of every
linear projection. Stock recipe: top 25% per module type. `training/spectrum.py`
is a faithful port of QuixiAI/spectrum (fp32 `svdvals` -> noise sigma via
IQR/1.349 -> Marchenko-Pastur edge `sigma*sqrt((1+sqrt(beta))^2)` -> SNR,
normalized by sigma_max; `int(count*pct/100)` per type), but streams safetensors
shards on CPU instead of loading the model.

```bash
# 1. scan — on the host holding the base weights (~5 min on 20 cores)
uv run --no-sync python spectrum.py \
  --model-dir ~/.cache/huggingface/hub/models--ornith-ai--Ornith-1.5-9B/snapshots/<hash> \
  --top-percent 25 --out spectrum_targets_ornith1.5_p25.json

# 2. map checkpoint names to the runtime tree and re-select. transformers 5.x
#    nests Qwen3.5 checkpoints under model.language_model.* but peft sees
#    model.layers.* — targeting the raw scan names fails with
#    NoMatchingPeftModuleError.
uv run --no-sync python spectrum.py \
  --from-snr-json spectrum_targets_ornith1.5_p25.json \
  --map-prefix model.language_model.=model. \
  --top-percent 25 --out spectrum_targets_runtime_p25.json

# 3. train — otherwise identical to qlora-v1
uv run qlora-train --out runs/qlora-v2-spectrum25 \
  --targets-file spectrum_targets_runtime_p25.json \
  --train data/sft/train.jsonl --val data/sft/val.jsonl \
  --max-len 4096 --group-by-length --bs 2 --accum 16 --eval-bs 8 --osp-first
```

`qlora-v2-spectrum25` (clarity2, `tmux:train`, `train_spectrum.log`): 32 of 128
runtime modules targeted (8/32 per MLP type, 2/8 per attention type — the arch
is a hybrid with full attention on only 8 of 32 layers plus a non-runtime MTP
head, which the mapping drops).

## Data

`build-sft` (a.k.a. `python -m training.sft_data`) joins `data/composer_dataset.jsonl`
(idiomatic rows only) to the locally cached
`nuprl/stack-dedup-python-testgen-starcoder-filter-v2` sources and
`data/js2jac_dataset_idiomatic.jsonl`, then writes:

- `training/data/sft/train.jsonl` / `val.jsonl` — `{id, task, split_key,
  prompt, completion}`, raw task texts, not chat-templated.
- `training/data/sft/holdout_problems.jsonl` — val rows with references, for
  `vllm-eval`. js rows carry `js`/`path` (fidelity gate); OSP rows carry
  `jac_tests`/`test_hash` (a real BEHAVIORAL gate is possible for OSP — 76 of
  the holdout rows ship a test annex, which is stronger evidence than anything
  available on the js side).

### Object-spatial rows (why they are here)

Before they were added the corpus contained **1 `walker` in 58k rows**: the
model would have learned Jac as typed Python plus a React dialect and never
seen the paradigm the language exists for. Two contracts are emitted separately
so the mix stays measurable: `osp_codegen` (natural-language spec -> OSP Jac,
prompt used verbatim so it matches the distribution the reference was generated
under) and `osp_lift` (non-OSP source -> OSP-lifted Jac).

Admission is `guard_result == "pass"` ONLY — i.e. the row's `jac_tests` annex
ran green. The 5,079 `legacy_compile_only` rows are excluded on purpose: they
carry `jac check` and nothing else, and testgen has already been run over them
at scale (32 ever PASSed, 4,401 ever SEMANTIC_FAILed). They are not awaiting
verification; they were verified and mostly failed. Do not "rescue" them by
re-running testgen — that experiment already returned its answer, and 1,120 of
those attempts died on `http 402` credit exhaustion. The ~658 never-tested and
~851 credit-exhausted ids are the only slice where a fresh probe is informative.

Current build (2026-09-28): **64,794 train / 1,234 val** — 26,994
py_translation + 26,994 py_completion + 4,155 js_translation + 1,904
osp_codegen + 313 osp_lift, plus 4,434 OSP upsample copies (`--upsample-osp 3`
duplicates each osp_codegen/osp_lift TRAIN row x3 under `-u2`/`-u3` id
suffixes, post-split, so val/holdout are never duplicated). OSP is ~10.3% of
the trained mix (was 3.7% — 6,651/64,794); 2 epochs x 3 copies = 6 passes per
unique OSP row, checked against the OSP holdout slice at eval. Re-run
`token-stats` after any mix change.

Prompts are the canonical builders imported from
`scripts/eval/build_function_eval.py` (`translation_prompt`,
`completion_prompt`, `split_completion`) plus a mirrored JS prompt, so train
and eval formatting cannot diverge.

plus `data/osp_merged_corpus.jsonl` (object-spatial rows, `guard_result ==
"pass"` only), then writes:

```bash
PYTHONPATH=training/src .venv/bin/python -m training.sft_data
```

## On the rented 4090 (CUDA 12.x, driver >= 570)

Any 24 GB card works. The v1 run trains on a lab RTX 3090 (Ampere — bf16,
NF4, paged optimizer all supported); at ~60-70% of a 4090's throughput the
2-epoch build is still ~4-7 h.

```bash
# one-time
uv sync --extra train            # torch/trl/peft/accelerate/bitsandbytes
hf auth login                    # gated/new arch downloads

# 1. size the context window (re-check after any mix change; 2026-09-28
#    upsampled build measured p99 2,714 with only 28 rows over 4096)
uv run token-stats --sft-dir training/data/sft     # set --max-len from p99

# 2. smoke: 500 rows, 100 steps — validates the whole path for <$1 of GPU
uv run qlora-train --smoke --out runs/qlora-smoke

# 3. full run: 48M train tokens (2 epochs)
#    4090 estimate 4-7 h; measured RTX 3090 (Qwen3.5 hybrid arch, fla kernels,
#    group_by_length, bs4): ~14 s/optimizer-step x ~4,050 steps ≈ 16 h.
#    `flash-linear-attention` is REQUIRED for sane speed (transformers falls
#    back to a slow reference impl for the gated-delta-rule layers otherwise).
uv run qlora-train --out runs/qlora-v1 --max-len 4096 --group-by-length

# 4. merge for serving (writes a SECOND full copy of the weights, ~19 GB)
uv run merge-adapter --adapter runs/qlora-v1 --out runs/qlora-v1-merged
#    disk-tight alternative: serve the adapter directly, no merged copy
#    vllm serve ornith-ai/Ornith-1.5-9B --enable-lora --lora-modules jac-sft=runs/qlora-v1
```

Defaults: lr 1e-4 cosine (warmup 100 steps), per-device bs 2 x accum 16
(global 32), paged_adamw_8bit, grad checkpointing, sdpa attention (`--attn
flash_attention_2` if you install flash-attn).

Config kwargs validated against torch 2.13 / transformers 5.17 / trl 1.14 /
peft 0.21 — TRL 1.x renamed `warmup_ratio` to `warmup_steps`; pin >= the
versions above or re-run `token-stats` + the smoke run after upgrades.

## Evaluation

```bash
uv sync --extra eval   # installs vllm 0.30; keep the train extra too or uv strips it
vllm serve runs/qlora-v1-merged --served-model-name jac-sft \
    --max-model-len 8192 --max-num-seqs 96 \
    --enable-auto-tool-choice --tool-call-parser qwen3_xml \
    --reasoning-parser qwen3 --trust-remote-code
# --max-num-seqs: each decode seq needs a Mamba cache block (gated-delta-rule
# layers); on a 24 GB card only ~98 blocks fit after weights + CUDA graphs, so
# the default 256 aborts engine init. --disable-log-requests is GONE in
# vllm >= 0.30 (request logs land in the server log; do not pass it).

# frozen function-suite: translation (+ completion) tasks, pass@k via grader
uv run vllm-eval --problems evals/function/v1/public/test.jsonl \
    --tasks translation --samples 4
.venv/bin/python scripts/eval/eval_jac.py \
    --problems evals/function/v1/private/test.jsonl \
    --samples runs/vllm_eval/jac-sft/samples.jsonl

# js2jac repo holdout: reference-free, two-stage deterministic gate
uv run vllm-eval --problems training/data/sft/holdout_problems.jsonl \
    --tasks js_translation --samples 1 --syntax-gate --fidelity-gate
```

`vllm-eval` defaults to `enable_thinking=False` (empty think block pre-filled
via the checkpoint's chat template — the same recipe the SFT targets train).
Measured 2026-09-30 on the js holdout: with thinking left open, the base prior
runs away on hard rows — 24% of samples burned all 4,096 max_tokens inside
`<think>` and returned EMPTY output (51.1% raw pass vs 71.6% with the prefill).
Pass `--thinking` to reproduce the open-block behavior. The completion track
never runs away (0/1,944 empty), but keep the default for a uniform protocol.

`--syntax-gate` runs `jac check`; `--fidelity-gate` adds the pipeline's
structural-fidelity gate (babel signature of the ORIGINAL JS vs export parity /
string retention / body mass in the candidate). Both come from
`scripts/js2jac_dataset/` via `training/gates.py`, so the eval and the data
build share one implementation. `jac check` alone is NOT a sufficient holdout
gate — it admits hollow stubs by construction; a compiling `obj Stub { has x:
int = 0; }` scores as a pass under syntax-only and is caught only by fidelity.
A sample passes only if every enabled stage passes; per-sample verdicts (with
the failing metric) land in `gate_report.jsonl` beside `samples.jsonl`.

Two flags make the number interpretable:

```bash
# the ceiling: gate the holdout REFERENCES. The gates are deterministic and
# conservative, so a substantial slice of ground truth fails. LATEST: 2026-09-30
# on the current 88-row js holdout = 84/88 pass (95.5%), syntax 95.5% (4 refs
# fail `jac check`), fidelity 100%. Earlier builds measured differently
# (2026-09-28, 108-row build: 77/108 = 71.3% with reasons {dropped-export 25,
# lossy-mass 23, hollow-strings 19}) -- the ceiling MOVES with the holdout
# build; re-measure it whenever the holdout selection or the thresholds change
# and report model/ceiling, never the raw rate. Do not retune T_MASS to flatter
# it. NOTE: fidelity silently SKIPS rows whose source JS babel cannot parse
# ("unparseable-source(skip)") -- check fidelity_reasons before trusting a 100%.
uv run vllm-eval --problems training/data/sft/holdout_problems.jsonl \
    --tasks js_translation --gate-references --syntax-gate --fidelity-gate

# re-gate an existing samples.jsonl (threshold changes cost no GPU)
uv run vllm-eval --problems ... --gate-only --syntax-gate --fidelity-gate
```

Baseline first: run `vllm-eval` against stock `ornith-ai/Ornith-1.5-9B`
served the same way, so adapter deltas are measured, not guessed.

### Function-suite results (qlora-v1, corrected 2026-10-03)

`evals/function/v1` test (972 problems x 4 samples): **pass@1 44.16%,
pass@2 46.09%, pass@4 47.06%**; statuses 1716 pass / 37 test_fail /
2129 check_fail / 5 timeout / 1 infra_error. Full tables, provenance, and
checksums: `archive/stock-sft-qlora-v1/REPORT.md`.

The originally reported pass@1 7.19% was a grading artifact: the 120s
execution cap timed out 1360/3888 samples. Regrading every timeout/infra
sample at a 300s cap recovers 1447 passes — 620 of them execute in >120s
(median 111s, p90 176s). check_rate (45.2%) is cap-independent. **Grade this
suite at >=300s** or report both caps.

## Known limitations

- `eval_jac.py` grading requires `evals/function/v1/private/` on the eval box;
  never train on it (the denylist guard is the reason that holds).
- js2jac rows carry no hidden tests, so the holdout is gated deterministically
  (`jac check` + structural fidelity), never behaviorally — a candidate can pass
  both and still be semantically wrong. The behavioral gates (`gates/
  behavioral_gate.py`, `orm_behavioral_gate.py`) need a runnable harness that
  harvested React/TS does not have in isolation.
- The fidelity gate needs `bun` (for the babel signature) and the `jac`
  checkout, so it runs on the eval box, not in CI.
- `--fidelity-gate` needs `js` on each problem row. `build-sft` now emits `js`
  and `path` into `holdout_problems.jsonl`; for holdout files built before that,
  the source is recovered from the fenced prompt automatically.
- The composer manifest in `data/MANIFEST.md` predates the current row count;
  `build-sft` prints live counts.
