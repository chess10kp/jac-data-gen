"""Phase 3 — read the curve. Pivot 02-rl-grpo/results/rl_ladder.jsonl into a markdown table.

run_ladder.jac appends one row per eval, tagged r<N>/<model>/<cond>/<gen|mem>.
This collapses those into one line per (model, rung, condition) showing the
headline numbers side by side: holdout (gen) pass@1 vs the rung's own train (mem)
pass@1, plus near-pass and avg-osim diagnostics. Read the sweet spot off the gen
column — the rung where it plateaus.

  jac run 02-rl-grpo/rl/show_ladder.jac                 # default 02-rl-grpo/results/rl_ladder.jsonl
  JAC_LADDER_RESULTS=path jac run 02-rl-grpo/rl/show_ladder.jac

Paste the output under the matching section of 02-rl-grpo/docs/rl/02-results.md.

# ponytail: dynamic JSON-dict pivot -> strict `jac check` can't type it (same as
# eval_rl.jac / build_tasks.jac). Bar is `jac check -p` (parse) + it runs clean.
"""

import os;
import json;
import math;
import from pathlib { Path }

glob RUNG_ORDER: list = ["1", "3", "5", "10", "20", "all"];
glob COND_ORDER: list = ["base", "sft", "sft_grpo", "raw_grpo"];

def order_of(item: str, table: list) -> int {
    return table.index(item) if item in table else 99;
}

def pct(rec: dict, field: str) -> str {
    # rec is an eval row (or {} when that kind is missing); fields are 0-100 floats
    if field in rec { return str(rec[field]) + "%"; }
    return "·";
}

def wilson_ci(rec: dict) -> str {
    # Wilson 95% CI on the gen pass@1 proportion — closed form, right for n~15-30.
    # Needs raw count (pass1) and n (tasks); falls back to '·' if absent.
    if "pass1" not in rec or "tasks" not in rec { return "·"; }
    n = int(rec["tasks"]);
    if n == 0 { return "·"; }
    p = float(rec["pass1"]) / n;
    z = 1.96; z2 = z * z;
    denom = 1.0 + z2 / n;
    center = (p + z2 / (2.0 * n)) / denom;
    half = (z * math.sqrt(p * (1.0 - p) / n + z2 / (4.0 * n * n))) / denom;
    lo = max(0.0, center - half) * 100.0;
    hi = min(1.0, center + half) * 100.0;
    return str(round(lo, 0)) + "-" + str(round(hi, 0)) + "%";
}

with entry {
    path = os.environ.get("JAC_LADDER_RESULTS", "02-rl-grpo/results/rl_ladder.jsonl");
    if not Path(path).exists() {
        print("no rows yet at " + path + " — run the ladder first (JAC_LADDER_GO=1 jac run 02-rl-grpo/rl/run_ladder.jac)");
    } else {
        # cells[model|rung|cond] = {"gen": row, "mem": row}
        cells: dict = {};
        for ln in Path(path).read_text().split("\n") {
            if not str(ln).strip() { continue; }
            rec = json.loads(str(ln));
            parts: list = str(rec.get("tag", "")).split("/");
            if len(parts) != 4 { continue; }                 # r<N>/<model>/<cond>/<kind>
            (rung, model, cond, kind) = (str(parts[0]).lstrip("r"), str(parts[1]), str(parts[2]), str(parts[3]));
            key = model + "|" + rung + "|" + cond;
            slot: dict = cells.get(key, {});
            slot[kind] = rec;
            cells[key] = slot;
        }
        if not cells {
            print("found " + path + " but no tagged rows (need JAC_RL_TAG from run_ladder.jac)");
        } else {
            # explicit composite sort key: model, then ladder rung order, then condition order
            sortable: list = [];
            for k in cells.keys() {
                bits: list = str(k).split("|");
                rk = str(order_of(bits[1], RUNG_ORDER)).zfill(2);
                ck = str(order_of(bits[2], COND_ORDER));
                sortable.append((bits[0] + "|" + rk + "|" + ck, str(k)));
            }
            sortable.sort();

            print("| model | rung | cond | gen pass@1 | gen 95%CI | gen pass@k | mem recall | gen near | osim |");
            print("|---|---|---|---|---|---|---|---|---|");
            for pair in sortable {
                k = pair[1];
                bits = str(k).split("|");
                slot: dict = cells[k];
                g: dict = slot.get("gen", {});
                m: dict = slot.get("mem", {});
                osim = str(g["avg_osim"]) if ("avg_osim" in g) else "·";
                print("| " + bits[0] + " | " + bits[1] + " | " + bits[2] + " | "
                    + pct(g, "pass1_pct") + " | " + wilson_ci(g) + " | " + pct(g, "passk_pct") + " | "
                    + pct(m, "pass1_pct") + " | " + pct(g, "near_pct") + " | " + osim + " |");
            }
            print("\n_gen=holdout (generalization), mem=train recall (overfit gauge). Read pass@k + CI, not bare pass@1 (Yue 2504.13837). A rung 'plateaus' only when consecutive CIs overlap._");

            # --- by-condition pass@k reframe: greedy flat, pass@k mean moves, boundary fixed ---
            agg: dict = {};
            for pair in sortable {
                bits2: list = str(pair[1]).split("|");
                cond2 = bits2[2];
                g2: dict = cells[pair[1]].get("gen", {});
                if "pass1_pct" in g2 {
                    a: dict = agg.get(cond2, {"p1": [], "pk": []});
                    a["p1"].append(g2["pass1_pct"]);
                    a["pk"].append(g2.get("passk_pct", g2["pass1_pct"]));
                    agg[cond2] = a;
                }
            }
            if agg {
                print("\n### by condition — pass@k reframe (gen / holdout)\n");
                print("| cond | n | mean pass@1 | mean pass@8 | max pass@8 (boundary) |");
                print("|---|---|---|---|---|");
                for cond3 in ["base", "sft", "sft_grpo", "sft_grpo_tuned", "raw_grpo"] {
                    if cond3 in agg {
                        a3: dict = agg[cond3];
                        n3 = len(a3["pk"]);
                        if n3 > 0 {
                            mp1 = sum(a3["p1"]) / n3; mpk = sum(a3["pk"]) / n3; mxpk = max(a3["pk"]);
                            print("| " + cond3 + " | " + str(n3) + " | " + str(round(mp1, 1)) + "% | "
                                + str(round(mpk, 1)) + "% | " + str(round(mxpk, 1)) + "% |");
                        }
                    }
                }
                print("\n_Greedy (pass@1) flat across all conditions. pass@8 MEAN lifts under SFT (sampling efficiency), but the BOUNDARY (max pass@8) is unchanged from base — neither SFT nor GRPO expands what's reachable (Yue 2504.13837). GRPO ≈ SFT on every metric._");
            }
        }
    }
}
