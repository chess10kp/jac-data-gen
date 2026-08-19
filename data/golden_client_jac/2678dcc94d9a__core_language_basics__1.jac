"""Within-candidate dedup via ROUGE-L (LCS) similarity on comment-stripped code.

Cheap first-pass dedup: compute the ROUGE-L F1 (longest-common-subsequence over
whitespace tokens of the comment-stripped Jac body) between each candidate and
the ones already kept; drop anything at or above the threshold. Threshold 0.6
follows the Recipe 2 within-candidate dedup rule.
"""

def code_tokens(code: str) -> list[str] {
    lines: list[str] = [];
    for line in code.split("\n") {
        stripped: str = line.split("#", 1)[0];
        if stripped.strip() != "" { lines.append(stripped); }
    }
    return " ".join(lines).split();
}


def lcs_len(a: list[str], b: list[str]) -> int {
    n: int = len(a);
    m: int = len(b);
    prev: list[int] = [0] * (m + 1);
    for i in range(1, n + 1) {
        cur: list[int] = [0] * (m + 1);
        for j in range(1, m + 1) {
            val: int = max(prev[j], cur[j - 1]);
            if a[i - 1] == b[j - 1] { val = prev[j - 1] + 1; }
            cur[j] = val;
        }
        prev = cur;
    }
    return prev[m];
}


def rouge_l(code_a: str, code_b: str) -> float {
    a: list[str] = code_tokens(code_a);
    b: list[str] = code_tokens(code_b);
    if len(a) == 0 or len(b) == 0 { return 0.0; }
    return (2.0 * lcs_len(a, b)) / (len(a) + len(b));
}


def dedup_examples(examples: list[dict], threshold: float = 0.6) -> tuple[list[dict], int] {
    kept: list[dict] = [];
    kept_codes: list[str] = [];
    removed: int = 0;
    for ex in examples {
        msgs: list = list(ex["messages"]);
        assistant: dict = dict(msgs[1]);
        code: str = str(assistant["content"]);
        dup: bool = False;
        for kc in kept_codes {
            if rouge_l(code, kc) >= threshold { dup = True; break; }
        }
        if dup { removed += 1; } else { kept.append(ex); kept_codes.append(code); }
    }
    return (kept, removed);
}
