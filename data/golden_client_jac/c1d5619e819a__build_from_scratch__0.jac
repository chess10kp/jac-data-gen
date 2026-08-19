import json;
import re;
import os;
import from pathlib { Path }

def _num(line: str, pattern: str) -> float {
    m = re.search(pattern, line);
    if m is None { return -1.0; }
    return float(str(m.group(1)));
}

def bar(value: float, lo: float, hi: float, width: int) -> str {
    if hi <= lo { return "#"; }
    n: int = int((value - lo) / (hi - lo) * width);
    out: str = "";
    for _ in range(n) { out += "#"; }
    return out;
}

with entry {
    train_log: str = os.environ.get("JAC_TRAIN_LOG", "01-sft-dpo/results/train.log");
    print("==================== TRAINING DASHBOARD ====================");
}
