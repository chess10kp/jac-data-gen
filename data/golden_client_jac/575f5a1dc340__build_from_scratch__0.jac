import os;
import re;
import json;
import glob;
import subprocess;
import from pathlib { Path }

def run_jac(jac_code: str, timeout: int = 30) -> tuple[int, str, str] {
    # Mirror of 01-sft-dpo/sft_dpo/jacgen/writer.jac:run_jac — the behavioral gate.
    import tempfile;
    with tempfile.TemporaryDirectory() as d {
        f = Path(str(d)) / "snippet.jac";
        f.write_text(jac_code);
        try {
            # cwd=d so jac's `.jac/` persistence is fresh per run (a persistent
            # `root` graph would otherwise accumulate state across drivers).
            p = subprocess.run(
                ["jac", "run", str(f)], capture_output=True, text=True, timeout=timeout, cwd=str(d)
            );
            return (p.returncode, p.stdout, p.stderr);
        } except (subprocess.SubprocessError, OSError) as e {
            return (124, "", str(e));
        }
    }
}

def parse_hole(text: str) -> dict {
    # Returns {ok, id, instruction, indent, start, end} where start/end are line
    lines = text.split("\n");
    start = -1;
    end = -1;
    for (i, ln) in enumerate(lines) {
        if ">>>HOLE" in ln { start = i; }
        elif "<<<HOLE" in ln { end = i; }
    }
    if start < 0 or end < 0 or end <= start {
        return {"ok": False};
    }
    m = re.search(r'>>>HOLE\s+id="([^"]+)"\s+instruction="(.*)"', lines[start]);
    if not m {
        return {"ok": False};
    }
    indent = re.match(r"\s*", lines[start]).group(0);
    return {
        "ok": True,
        "id": str(m.group(1)),
        "instruction": str(m.group(2)),
        "indent": indent,
        "start": start,
        "end": end,
        "lines": lines
    };
}

def replace_region(lines: list, start: int, end: int, repl_lines: list) -> str {
    out = lines[:start] + repl_lines + lines[end + 1:];
    return "\n".join(out);
}

def sg_bucket(tid: str) -> str {
    # social_graph.jac is one 32-task file (~half the corpus) — too big to hold out
    # whole, so its OSP-walker idiom can never sit in a file-disjoint holdout. Split
    # it into 4 feature buckets so build_rl_splits can reserve a coherent sg slice
    # (e.g. all 'tweet' walkers) and measure sg-idiom generalization.
    if "channel" in tid { return "channel"; }
    if ("tweet" in tid) or ("comment" in tid) or ("like" in tid) { return "tweet"; }
    if "profile" in tid { return "profile"; }
    return "feed";   # feed / follow / trending / user / etc.
}

with entry {
    drivers = sorted(glob.glob("02-rl-grpo/rl/drivers/*.jac"));
    os.makedirs("02-rl-grpo/dataset/rl/templates", exist_ok=True);
    tasks_path = "02-rl-grpo/dataset/rl/tasks.jsonl";
    open(tasks_path, "w").close();   # truncate — full rebuild each run

    built = 0;
    failed = 0;
    for path in drivers {
        text = Path(path).read_text();
        info = parse_hole(text);
        if not info["ok"] {
            print("SKIP (no valid HOLE): " + path);
            failed += 1;
            continue;
        }
        # ground-truth output: run the driver exactly as authored
        (code, out, err) = run_jac(text);
        if code != 0 or not out.strip() {
            print("FAIL (driver did not run clean): " + path + "  exit=" + str(code));
            print("   " + err.strip()[:200]);
            failed += 1;
            continue;
        }
        # determinism guard: a task whose stdout varies run-to-run is unusable as
        # an exact-match RL target (jid()/time/unseeded-rng leak). Re-run once.
        (code2, out2, err2) = run_jac(text);
        if out2 != out {
            print("FAIL (NONDETERMINISTIC stdout): " + path);
            failed += 1;
            continue;
        }
        # origin source file (for file-disjoint holdout in build_rl_splits.jac)
        src_m = re.search(r"Origin:\s*(this_is_jac/\S+?\.jac)", text);
        source = str(src_m.group(1)) if src_m else "unknown";
        # OPT-IN (JAC_RL_SG_BUCKETS=1): bucket the one big social_graph.jac into
        # feature sub-sources so its idiom can be held out file-disjoint. Off by
        # default so the established gb+lib-holdout ladder stays reproducible; the
        # step-7 sg-generalization run turns it on (+ its own results file).
        if ("social_graph.jac" in source) and (os.environ.get("JAC_RL_SG_BUCKETS", "") == "1") {
            source = source + "::" + sg_bucket(info["id"]);
        }

        lines = info["lines"];
        indent = info["indent"];
        # template: body region -> a single __HOLE__ sentinel line
        template = replace_region(lines, info["start"], info["end"], [indent + "__HOLE__"]);
        # prompt view: body region -> a TODO placeholder
        prompt_view = replace_region(
            lines, info["start"], info["end"],
            [indent + "# TODO: write the body for this unit"]
        );
        prompt = (
            info["instruction"]
            + "\n\nComplete the Jac file below: replace the `# TODO` line with the"
            + " correct Jac code for that unit. Return only the replacement code,"
            + " in a
