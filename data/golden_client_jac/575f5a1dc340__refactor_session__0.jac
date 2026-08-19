"""Build GRPO tasks from authored RL drivers.

Each `02-rl-grpo/rl/drivers/*.jac` is a complete, deterministic `jac run`-able file with one
unit's body wrapped in sentinels:

    # >>>HOLE id="..." instruction="..."
    <body statements>
    # <<<HOLE

For every driver this emits one GRPO record to `02-rl-grpo/dataset/rl/tasks.jsonl`.
"""

import os;
import re;
import json;
import glob;
import subprocess;
import from pathlib { Path }

def run_jac(jac_code: str, timeout: int = 30) -> tuple[int, str, str] {
    import tempfile;
    with tempfile.TemporaryDirectory() as d {
        f = Path(str(d)) / "snippet.jac";
        f.write_text(jac_code);
        try {
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
    im = re.match(r"\s*", lines[start]);
    indent = im.group(0) if im else "";
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

def build_prompt(instruction: str, prompt_view: str) -> str {
    return (
        instruction
        + "\n\nComplete the Jac file below: replace the `# TODO` line with the"
        + " correct Jac code for that unit. Return only the replacement code,"
        + " in a
