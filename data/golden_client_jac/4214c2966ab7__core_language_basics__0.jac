"""Build python->jac CONVERSION tasks from the pure-function sidecars.

POC of the conversion task format. For every `02-rl-grpo/rl/conversion/<id>.py` sidecar whose
hole-fill task already exists, emit a record to `02-rl-grpo/dataset/rl_conv/tasks.jsonl` that
REUSES the hole-fill template + answer meta (id / source / expected_output / timeout)
— only the PROMPT changes: show the Python function + the Jac file with a `# TODO`
body, ask for the equivalent Jac. Grading (eval_rl.jac / reward) is unchanged: splice
the model's Jac into `templates/<id>.jac`, run, compare stdout.

  jac run 02-rl-grpo/rl/build_tasks.jac          # (first — makes templates/ + refbodies/)
  jac run 02-rl-grpo/rl/build_conversion_tasks.jac
"""

import os;
import json;
import glob;
import from pathlib { Path }

with entry {
    tasks_path = "02-rl-grpo/dataset/rl/tasks.jsonl";
    if not Path(tasks_path).exists() {
        print("MISSING " + tasks_path + " — run: jac run 02-rl-grpo/rl/build_tasks.jac");
        import sys;
        sys.exit(1);
    }
    # id -> raw answer JSON string (reused verbatim so eval/reward behave identically)
    ans_by_id: dict = {};
    for ln in Path(tasks_path).read_text().split("\n") {
        s = str(ln).strip();
        if not s { continue; }
        rec = json.loads(s);
        meta = json.loads(str(rec["answer"]));
        ans_by_id[str(meta["id"])] = str(rec["answer"]);
    }

    os.makedirs("02-rl-grpo/dataset/rl_conv", exist_ok=True);
    out: list = [];
    built = 0; skipped = 0;
    for sc in sorted(glob.glob("02-rl-grpo/rl/conversion/*.py")) {
        tid = os.path.basename(sc)[:-3];   # strip .py
        tmpl_path = "02-rl-grpo/dataset/rl/templates/" + tid + ".jac";
        if (tid not in ans_by_id) or (not Path(tmpl_path).exists()) {
            print("SKIP (no matching task): " + tid);
            skipped += 1;
            continue;
        }
        py = Path(sc).read_text().strip();
        template = Path(tmpl_path).read_text();
        jac_todo = template.replace("__HOLE__", "# TODO: write the equivalent Jac code for this unit's body");
        prompt = (
            "Convert the following Python function to idiomatic Jac. Replace the `# TODO` "
            + "line in the Jac file below with the Jac code equivalent to the Python. Return "
            + "only the replacement code, in a
