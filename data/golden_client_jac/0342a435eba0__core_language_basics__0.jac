"""Generate conversion DPO pairs (Recipe 3: de-Python-ification).

A DPO pair needs an idiomatic `chosen`, which only the hand/mined-crafted core
in sft.jsonl provides. For each such example this pairs the idiomatic Jac
(chosen) against a `jac py2jac` transpile of the SAME Python (rejected) -- the
literal Python-shaped Jac the finetune must learn to avoid. The mechanical
transpile IS the adversarial negative, so this scales automatically to the size
of the idiomatic core (not to the 1500-example volume tier, which has no
idiomatic partner).

Run from the repo root:
    jac run srccurrent/jacgen/dpo_conversion.jac
"""

import json;
import subprocess;
import tempfile;
import from corpus { transpile, sanitize_transpile }
import from writer { append_jsonl }
import from pathlib { Path }
import from typing { Any }


def compiles(jac_code: str) -> bool {
    # PARSE-only gate (`jac check -p`), not strict `jac check`: aligns with the
    # project rule "valid/runnable Jac, not type-checker-approved Jac". Strict
    # check rejects the graph transpile (untyped dict/set Any) even though it
    # parses+runs fine, which dropped all graph DPO pairs.
    with tempfile.TemporaryDirectory() as d {
        fp = Path(str(d)) / "r.jac";
        fp.write_text(jac_code);
        try {
            proc = subprocess.run(["jac", "check", "-p", str(fp)], capture_output=True, text=True, timeout=30);
        } except (subprocess.SubprocessError, OSError) {
            return False;
        }
        return proc.returncode == 0;
    }
}

glob SFT_PATH: str = "01-sft-dpo/dataset/conversion/sft.jsonl";
glob DPO_PATH: str = "01-sft-dpo/dataset/conversion/dpo.jsonl";


def extract_python(user: str) -> str {
    after: str = user.split("
