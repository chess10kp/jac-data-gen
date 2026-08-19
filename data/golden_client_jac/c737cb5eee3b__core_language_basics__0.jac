"""Record ALL ladder results into 02-rl-grpo/docs/rl/02-results.md (the living results doc).

Runs show_ladder.jac (the single source of truth for the pivot table) and wraps
its output with a header, the method/reward summary, and provenance. Re-run after
each ladder stage to refresh the doc.

  jac run 02-rl-grpo/rl/record_results.jac
"""

import os;
import datetime;
import subprocess;
import from pathlib { Path }

glob ROOT: str = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))));
glob JAC: str = os.path.join(ROOT, ".venv", "bin", "jac") if os.path.exists(os.path.join(ROOT, ".venv", "bin", "jac")) else "jac";

with entry {
    p = subprocess.run([JAC, "run", "02-rl-grpo/rl/show_ladder.jac"], capture_output=True, text=True, cwd=ROOT);
    table = p.stdout.strip();
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M");

    # Step 7: the sg-inclusive holdout run (separate file), if present
    sg_table = "";
    sg_path = os.path.join(ROOT, "02-rl-grpo", "results", "rl_ladder_sg.jsonl");
    if os.path.exists(sg_path) {
        env2 = dict(os.environ); env2["JAC_LADDER_RESULTS"] = sg_path;
        sp = subprocess.run([JAC, "run", "02-rl-grpo/rl/show_ladder.jac"], capture_output=True, text=True, cwd=ROOT, env=env2);
        sg_table = sp.stdout.strip();
    }
    # The 84-task higher-power re-run (62 trainpool, harder holdout), if present
    v84_table = "";
    v84_path = os.path.join(ROOT, "02-rl-grpo", "results", "rl_ladder_v84.jsonl");
    if os.path.exists(v84_path) {
        env3 = dict(os.environ); env3["JAC_LADDER_RESULTS"] = v84_path;
        vp = subprocess.run([JAC, "run", "02-rl-grpo/rl/show_ladder.jac"], capture_output=True, text=True, cwd=ROOT, env=env3);
        v84_table = vp.stdout.strip();
    }

    doc = (
        "# RL Ladder — Results\n\n"
        + "> ## ⚠️ INVALIDATED — do not trust the numbers below\n"
        + "> These ladder numbers were produced by a **broken eval+reward** that "
        + "undercounted accuracy ~3.5–4× (the body extractor grabbed the driver "
        + "docstring). The corrected results are in the root **`RL_FINDINGS.md`** "
        + "(SFT actually lifts greedy 39%→61%, best-of-k ships ~78%). Kept only as a "
        + "record of the broken run.\n\n"
        + "*Auto-recorded " + ts + " by `02-rl-grpo/rl/record_results.jac` from `02-rl-grpo/results/rl_ladder.jsonl`. "
        + "Re-run after each ladder stage. Live version also renders in the Studio RL section.*\n\n"
        + "**Method:** SFT-first ladder (train-N = 1,3,5,10,20,all) × 2 models × conditions "
        + "{base, SFT(gold), SFT+GRPO, raw-GRPO control}. Holdout is file-disjoint + decontaminated; "
        + "headline = exact-stdout pass@1 with Wilson 95% CI + sampled pass@k.\n\n"
        + "**Reward (GRPO):** tiered monotone — exact=1.0 > runs-wrong≤0.80 > compiles≤0.35 > none≤0.15, "
        + "with a dense body-sim term in every tier (breaks the σ=0 trap).\n\n"
        + "## Ladder cells — primary holdout (gb+lib, file-disjoint)\n\n"
        + table + "\n\n"
        + (("## Step 7 — sg-inclusive holdout (sg idiom held out file-disjoint)\n\n"
            + "Re-sourced social_graph into feature buckets (`JAC_RL_SG_BUCKETS=1`) so the sg "
            + "OSP-walker idiom sits in the holdout. The held-out sg slice is the hard frontier "
            + "(0/5 for base, both models); fresh qwen3coder SFT at rung-all is the only cell to "
            + "crack it (sg 0->1/5, overall 14.3%->28.6%).\n\n"
            + sg_table + "\n\n") if sg_table else "")
        + (("## Higher-power re-run — 84-task corpus (62 trainpool, harder holdout)\n\n"
            + "Re-ran the full ladder after squeezing the corpus to 84 tasks (social_graph "
            + "48.5%->38.1%). Holdout is harder (base ~11% vs 27%), giving more headroom — yet the "
            + "result REPRODUCES: greedy pass@1 flat (~11%, SFT +1.4pp = noise), pass@8 mean lifts "
            + "under SFT/GRPO but base's max-pass@8 (38.9%) is still the highest. The null holds on "
            + "two independent corpora.\n\n"
            + v84_table + "\n\n") if v84_table else "")
        + "See [strat.md](strat.md) for hypotheses, [references.md](references.md) for the "
        + "literature, and [RL_WEEKEND_RESULTS.md](RL_WEEKEND_RESULTS.md) for the prior GRPO archive.\n"
    );
    Path(os.path.join(ROOT, "02-rl-grpo", "docs", "rl", "02-results.md")).write_text(doc);
    print("wrote 02-rl-grpo/docs/rl/02-results.md (" + str(len(table)) + " chars of table)");
}
