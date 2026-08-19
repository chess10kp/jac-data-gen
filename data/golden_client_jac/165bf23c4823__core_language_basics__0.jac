"""Rejection-sampling fine-tune (RFT) data builder — the GRPO warm-start.

Cold bases (fresh Qwen3-Coder, Qwen3.6) emit mostly non-compiling Jac, so GRPO
sees ~all-zero reward and stalls. RFT bootstraps a non-zero compile/pass rate:
sample completions from the base, keep the ones that PASS the *same* reward
oracle, and write them as SFT examples. A short LoRA SFT on these (run_rft.sh)
warms the base; GRPO then has signal to climb.

Loads the model once (eval pattern), and for each train task samples up to
RFT_SAMPLES completions at temperature RFT_TEMP, scoring each with
reward_logic.score_one. The first completion scoring >= RFT_PASS is kept as an
SFT example. Output: 02-rl-grpo/dataset/rl/rft/{train,valid}.jsonl (mlx messages format).

  JAC_EVAL_MODEL=models/qwen-q4 jac run 02-rl-grpo/rl/rft_sample.jac

Env: JAC_EVAL_MODEL (required), JAC_EVAL_ADAPTER (""), RFT_SAMPLES (8),
     RFT_TEMP (1.0), RFT_PASS (0.9 = behaviourally correct; lower to 0.6 =
     compiles+runs for very cold bases), RFT_SRC (02-rl-grpo/dataset/rl/train.jsonl).
Lazy-imports mlx_lm -> parse-check only (-p).
"""

import os;
import json;
import from pathlib { Path }
import from reward_logic { score_one, extract_jac }

def load_model(mp: str, adapter: str) -> tuple {
    import mlx_lm;
    if adapter {
        return mlx_lm.load(mp, adapter_path=adapter);
    }
    return mlx_lm.load(mp);
}

def gen_mlx(model: any, tok: any, prompt: str, temp: float) -> str {
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

with entry {
    mp: str = os.environ.get("JAC_EVAL_MODEL", "");
    adapter: str = os.environ.get("JAC_EVAL_ADAPTER", "");
    samples: int = int(os.environ.get("RFT_SAMPLES", "8"));
    temp: float = float(os.environ.get("RFT_TEMP", "1.0"));
    thresh: float = float(os.environ.get("RFT_PASS", "0.9"));
    src: str = os.environ.get("RFT_SRC", "02-rl-grpo/dataset/rl/train.jsonl");
    outdir: str = os.environ.get("RFT_OUT", "02-rl-grpo/dataset/rl/rft");   # STaR uses distinct dirs per round
    if not mp {
        print("set JAC_EVAL_MODEL");
    } else {
        (model, tok) = load_model(mp, adapter);
        lines = [l for l in Path(src).read_text().split("\n") if l.strip()];
        kept: list = [];
        covered = 0;
        for ln in lines {
            rec = json.loads(ln);
            prompt = str(rec["prompt"]);
            ans = str(rec["answer"]);
            got = False;
            for k in range(samples) {
                gen = gen_mlx(model, tok, prompt, temp);
                if score_one(gen, ans) >= thresh {
                    body = extract_jac(gen);
                    kept.append({
                        "messages": [
                            {"role": "user", "content": prompt},
                            {"role": "assistant", "content": "
