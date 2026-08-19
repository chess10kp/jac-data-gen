"""The ladder driver — Phase 1 + 2 of 02-rl-grpo/docs/rl/workflow.md, one command.

For each rung (train-N in 1,3,5,10,20,all) and each model, run the three design
conditions and eval each on BOTH the fixed holdout (gen) and the rung's own train
set (mem):

  base            base model, no training            (rung-0 floor)
  A  SFT          gold-SFT LoRA on the N tasks        (run_rft.sh, fused -> warm)
  B  SFT+GRPO     GRPO on the SFT warm model          (run_grpo.sh)
  C  raw-GRPO     GRPO on the un-SFT'd base (control)  (expect sigma=0 stall)

Every step REUSES the existing primitives (pick_rung / build_sft_gold / run_rft.sh
/ run_grpo.sh / eval_rl.jac) — this file only loops and threads paths. Eval rows
append to 02-rl-grpo/results/rl_ladder.jsonl tagged JAC_RL_TAG=r<N>/<model>/<cond>/<gen|mem>.

DRY by default: prints the exact command plan and writes nothing heavy. Each cell
is hours of MLX compute, so launching is opt-in:

  jac run 02-rl-grpo/rl/run_ladder.jac                       # dry: print the whole plan
  JAC_LADDER_GO=1 jac run 02-rl-grpo/rl/run_ladder.jac        # actually run it (sequential)

Env:
  JAC_LADDER_RUNGS   default "1,3,5,10,20,all"
  JAC_LADDER_MODELS  "name:base_q4_path:group_size" csv,
                     default "qwen3coder:models/qwen-q4:4,jac-qwen3coder:models/jac-qwen3coder-q4:4"
  JAC_LADDER_CONDITIONS  csv subset of base,sft,sft_grpo,raw_grpo (default all). Run
                     the cheap SFT curve first ("base,sft") to find the elbow, THEN
                     "sft_grpo" at just that rung — saves ~half the GPU-hours. Note
                     sft_grpo needs the warm model from a prior sft run on that rung.
  GRPO_LR/GRPO_ITERS/...  flow through to run_grpo.sh (env inherited). For a tuned-
                     GRPO arm set e.g. GRPO_LR=1e-5 GRPO_ITERS=500 before launching.
  JAC_LADDER_GO      "1" to execute; anything else = dry plan only

# ponytail: shell=True launcher over the existing scripts. Internal tool, paths
# are ours, not user input. A step that fails is logged and the ladder continues.
"""

import os;
import subprocess;
import from pathlib { Path }

glob OUT: str = os.environ.get("JAC_LADDER_OUT", "02-rl-grpo/results/rl_ladder.jsonl");   # step 7 uses a separate file
glob GO: bool = os.environ.get("JAC_LADDER_GO", "") == "1";

def sh(cmd: str) -> int {
    # env-prefixed shell string; print always, execute only when GO.
    print(("RUN " if GO else "DRY ") + cmd);
    if not GO {
        return 0;
    }
    p = subprocess.run(cmd, shell=True, cwd=os.getcwd());
    if p.returncode != 0 {
        print("  !! step failed (rc=" + str(p.returncode) + ") — continuing ladder");
    }
    return p.returncode;
}

glob K: str = os.environ.get("JAC_LADDER_K", "8");   # pass@k on gen evals (Yue 2504.13837: read pass@k)

def ev(model: str, adapter: str, kind: str, tag: str) -> None {
    # kind = "gen" (holdout, greedy pass@1 + sampled pass@K) or "mem" (train recall, greedy only)
    hold = "02-rl-grpo/dataset/rl/holdout.jsonl" if kind == "gen" else "02-rl-grpo/dataset/rl/train.jsonl";
    env = "JAC_EVAL_MODEL=" + model + " ";
    if adapter {
        env += "JAC_EVAL_ADAPTER=" + adapter + " ";
    }
    if kind == "gen" {
        env += "JAC_EVAL_K=" + K + " JAC_EVAL_TEMP=1.0 ";   # sampled pass@K reveals RL distribution shifts greedy hides
    }
    env += "JAC_RL_HOLDOUT=" + hold + " JAC_RL_OUT=" + OUT + " JAC_RL_TAG=" + tag + "/" + kind + " ";
    sh(env + "jac run 02-rl-grpo/rl/eval_rl.jac");
}

with entry {
    rungs = os.environ.get("JAC_LADDER_RUNGS", "1,3,5,10,20,all").split(",");
    spec = os.environ.get(
        "JAC_LADDER_MODELS",
        "qwen3coder:models/qwen-q4:4,jac-qwen3coder:models/jac-qwen3coder-q4:4"
    );
    models = [s.split(":") for s in spec.split(",") if s.strip()];
    conds: set = set([c.strip() for c in os.environ.get("JAC_LADDER_CONDITIONS", "base,sft,sft_grpo,raw_grpo").split(",") if c.strip()]);

    if not Path("02-rl-grpo/dataset/rl/trainpool.jsonl").exists() {
        print("MISSING 02-rl-grpo/dataset/rl/trainpool.jsonl — run: jac run 02-rl-grpo/rl/build_rl_splits.jac first");
        import sys;
        sys.exit(1);
    }
    Path("results").mkdir(exist_ok=True);
    print("=== ladder " + ("EXECUTE" if GO else "DRY-RUN") + " ===");
    print("  rungs:  " + str(rungs));
    print("  models: " + str([m[0] for m in models]));
    print("  rows -> " + OUT + "   (tag = r<N>/<model>/<cond>/<gen|mem>)\n");

    for rung in rungs {
        print("######## RUNG " + rung + " ########");
        sh("RUNG=" + rung + " jac run 02-rl-grpo/rl/pick_rung.jac");      # rung's train.jsonl (superset-grow)
        sh("jac run 02-rl-grpo/rl/build_sft_gold.jac");                  # gold SFT set for those N tasks
        for m in models {
            (name, base, gs) = (m[0], m[1], m[2]);
            tag = "r" + rung + "/" + name;
            warm = "models/" + name + "-r" + rung + "-rft-q4";
            sg_adapter = "02-rl-grpo/adapters/" + name + "-r" + rung + "-sg-grpo";
            raw_adapter = "02-rl-grpo/adapters/" + name + "-r" + rung + "-raw-grpo";
            print("---- " + tag + "  (base=" + base + " group=" + gs + ") ----");

            # rung-0 floor
            if "base" in conds {
                ev(base, "", "gen", tag + "/base");
                ev(base, "", "mem", tag + "/base");
            }
            # A) gold-SFT -> fused warm model
            if "sft" in conds {
                sh("RL_BASE=" + base + " RFT_ITERS=200 ./02-rl-grpo/rl/run_rft.sh " + name + "-r" + rung);
                ev(warm, "", "gen", tag + "/sft");
                ev(warm, "", "mem", tag + "/sft");
            }
            # B) SFT + GRPO  (needs the warm model from condition A on this rung)
            if "sft_grpo" in conds {
                sh("RL_BASE=" + warm + " GROUP_SIZE=" + gs + " ./02-rl-grpo/rl/run_grpo.sh " + name + "-r" + rung + "-sg");
                ev(warm, sg_adapter, "gen", tag + "/sft_grpo");
                ev(warm, sg_adapter, "mem", tag + "/sft_grpo");
            }
            # C) raw-base GRPO control (nonzero gradient via sim, expect no greedy shift)
            if "raw_grpo" in conds {
                sh("RL_BASE=" + base + " GROUP_SIZE=" + gs + " ./02-rl-grpo/rl/run_grpo.sh " + name + "-r" + rung + "-raw");
                ev(base, raw_adapter, "gen", tag + "/raw_grpo");
                ev(base, raw_adapter, "mem", tag + "/raw_grpo");
            }
        }
    }
    print("\n=== ladder " + ("done" if GO else "plan printed — set JAC_LADDER_GO=1 to run") + " ===");
}
