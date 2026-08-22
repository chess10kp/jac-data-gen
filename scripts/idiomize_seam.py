"""Shared idiomize seam: prompt + two callers — opencode CLI and direct zen API.

- opencode_idiomize: `opencode run --pure` (agent-shaped, ~40-90s/call; proofs only).
- zen_idiomize: direct thin POST to https://opencode.ai/zen/v1 (the free opencode
  gateway), OpenAI-compatible. ~10-15s/call, fully parallelizable, $0 cost.
  This is the path that scales the idiomize batch.

The model is a reasoning model, so max_tokens must be large (reasoning eats ~1k
tokens before the answer). zen_idiomize retries 429s with backoff.

System prompt anchors the model on Jac syntax; unanchored models emit Python
(weak Jac prior). It is built by `system_prompt()`: inline HARD_RULES (the
non-negotiable output contract, always present) + the Tier 0-2 sections of the
`jac-idiomatic` skill (SKILL.md + function-patterns.md) + a few-shot. The skill
is the single source of idiom guidance; if it is missing the seam degrades to
HARD_RULES + few-shot rather than failing.
"""
from __future__ import annotations
import json
import os
import re
import subprocess
import time
from pathlib import Path

import httpx

FENCE = re.compile(r"```jac\s*\n(.*?)```", re.S)
ZEN_BASE = "https://opencode.ai/zen/v1"

# --------------------------------------------------------------------------- #
# System prompt = compact HARD RULES (always inline) + Tier-A skill body loaded
# from the jac-idiomatic skill. The skill is the single source of truth for
# idiom guidance; this seam just anchors the reasoning model on the
# non-negotiable output contract and injects the function-level tiers.
# --------------------------------------------------------------------------- #
SKILL_DIR = Path(__file__).resolve().parent.parent / ".cursor/skills/jac-idiomatic"

# HARD RULES stay inline so the pipeline still produces valid, guardable output
# even if the skill files are missing. Everything else comes from the skill.
HARD_RULES = """You are an expert Jac (Jaseci Labs) engineer. Rewrite the mechanical
py2jac function into IDIOMATIC JAC. The input floor is ALREADY Jac.

HARD RULES (any violation discards your output):
1. OUTPUT VALID JAC ONLY. Jac uses braces { } for every block and a semicolon ;
   after every statement — EXACTLY like the floor. NEVER Python's colon-and-
   indentation. If your output has `def ...():` with a colon, it is WRONG.
2. KEEP THE FUNCTION NAME EXACTLY — do NOT rename it, do NOT snake_case it.
   The hidden tests call it by its current name.
3. Identical behavior — the hidden test suite discards any semantic drift.
4. This is a pure MultiPL-T function: apply Tier 0-2 (syntax, types, features)
   ONLY. Do NOT add walker/node/edge, `with entry`, `by llm`, or test blocks.
5. NEVER use `any` as a type. Infer a concrete type from the Python source and
   usage (str, int, float, bool, bytes, list[T], dict[K,V], tuple[...], T | None).
   `any`, `list[any]`, `-> any` are all FORBIDDEN — a real type always exists.
6. NEVER backtick-escape an identifier that is not a Jac reserved keyword.
   `list`, `dict`, `set`, `switch`, `obj` used as ordinary names/builtins are
   plain identifiers — write `list(...)`, not `` `list(...) ``. Backticks are
   ONLY for genuine keywords used as names (rare); when unsure, omit the backtick.
7. ALWAYS end every execution path with an EXPLICIT `return <expr>;` statement.
   Jac's implicit last-expression return is valid but FORBIDDEN here — the
   corpus must be stylistically uniform with an explicit `return`.
8. Output ONLY one ```jac fenced block containing the function. No prose.

The idiom guidance below is your rewrite playbook. Follow it, stopping any
transform that would break behavior.
"""

# H2 sections of SKILL.md that apply to Tier-A pure-function idiomize. The "What
# idiomatic means" section leads so the model has the concept (idiomatic = Jac
# features/types, not Python-in-braces), not just a rule checklist. Tier 3/4/5
# (OSP / fullstack / byLLM) are omitted as noise for MultiPL-T functions.
_SKILL_SECTIONS = ('What "idiomatic"', "Tier 0", "Tier 1", "Tier 2",
                   "Rewrite workflow", "Anti-patterns")


def _select_h2(md: str, prefixes: tuple[str, ...]) -> str:
    """Keep only the H2 sections whose title starts with one of `prefixes`."""
    out: list[str] = []
    keep = False
    for line in md.splitlines():
        if line.startswith("## "):
            keep = line[3:].strip().startswith(prefixes)
        if keep:
            out.append(line)
    return "\n".join(out).strip()


def _load_skill_body() -> str:
    """Tier-A skill body: selected SKILL.md tiers + full function-patterns.md.

    Returns "" if the skill is unavailable, so the seam degrades to HARD_RULES
    + few-shot rather than crashing.
    """
    parts: list[str] = []
    skill = SKILL_DIR / "SKILL.md"
    patterns = SKILL_DIR / "function-patterns.md"
    if skill.exists():
        sel = _select_h2(skill.read_text(), _SKILL_SECTIONS)
        if sel:
            parts.append(sel)
    if patterns.exists():
        parts.append(patterns.read_text().strip())
    return "\n\n---\n\n".join(parts)


_SYSTEM_CACHE: str | None = None


def system_prompt() -> str:
    """Full system message: HARD_RULES + skill body + few-shot. Cached."""
    global _SYSTEM_CACHE
    if _SYSTEM_CACHE is None:
        body = _load_skill_body()
        chunks = [HARD_RULES]
        if body:
            chunks.append(body)
        chunks.append(FEWSHOT)
        _SYSTEM_CACHE = "\n\n".join(chunks)
    return _SYSTEM_CACHE


# Back-compat alias: some callers referenced RULES as the system-prompt head.
RULES = HARD_RULES

FEWSHOT = """### Example of the transformation (Jac in -> Jac out)
Floor:
```jac
def add(a: Any, b: Any) -> object {
    return (a + b);
}
```
Idiomatic:
```jac
def add(a: int, b: int) -> int {
    return a + b;
}
```
Note: braces and semicolons are KEPT (Jac), parens dropped, real types added, name unchanged.
"""


def _user(floor_fn: str, py: str, entrypoint: str) -> str:
    return (f"### Python (original)\n```python\n{py}\n```\n\n"
            f"### Jac (mechanical floor) — keep this syntax\n```jac\n{floor_fn}\n```\n\n"
            f"Output the idiomatic ```jac block for `{entrypoint}` (name unchanged).")


def build_prompt(floor_fn: str, py: str, entrypoint: str) -> str:
    return system_prompt() + "\n" + _user(floor_fn, py, entrypoint)


def extract_jac(text: str) -> str | None:
    m = FENCE.search(text or "")
    return m.group(1).strip() if m else None


# --------------------------------------------------------------------------- #
# Direct zen API (free opencode gateway) — the scalable path
# --------------------------------------------------------------------------- #
def _opencode_key() -> str:
    k = os.environ.get("OPENCODE_KEY")
    if k and k.startswith("sk-"):
        return k
    for p in (Path.home() / ".pi/agent/auth.json",
              Path.home() / ".local/share/opencode/auth.json"):
        if p.exists():
            try:
                d = json.loads(p.read_text())
                if isinstance(d, dict) and d.get("opencode", {}).get("key"):
                    return d["opencode"]["key"]
            except Exception:  # noqa: BLE001
                pass
    raise RuntimeError("opencode key not found (set OPENCODE_KEY or configure pi/opencode auth)")


def zen_idiomize(floor_fn: str, py: str, entrypoint: str,
                 model: str = "deepseek-v4-flash-free", max_tokens: int = 16384,
                 timeout: float = 180, temperature: float | None = None
                 ) -> tuple[str | None, float]:
    """Thin POST to opencode zen gateway. Returns (jac_or_None, elapsed_s).

    Retries 429/5xx with exponential backoff (4 attempts). The model is a
    reasoning model -> content lives in choices[0].message.content after it
    finishes thinking; we give it max_tokens room for both. `temperature` lets
    the k-sampler request diverse candidates (see zen_idiomize_k).
    """
    key = _opencode_key()
    body = {
        "model": model, "max_tokens": max_tokens,
        "messages": [
            {"role": "system", "content": system_prompt()},
            {"role": "user", "content": _user(floor_fn, py, entrypoint)},
        ],
    }
    if temperature is not None:
        body["temperature"] = temperature
    headers = {"Authorization": f"Bearer {key}", "Content-Type": "application/json"}
    t0 = time.perf_counter()
    for attempt in range(4):
        try:
            r = httpx.post(f"{ZEN_BASE}/chat/completions", headers=headers,
                           json=body, timeout=timeout)
            if r.status_code in (429, 500, 502, 503, 504):
                time.sleep(2 ** attempt); continue
            if 400 <= r.status_code < 500:
                # client error (bad model id, auth, malformed) — not transient.
                # Fail fast instead of burning 4x backoff x k on every record.
                return None, time.perf_counter() - t0
            r.raise_for_status()
            content = r.json()["choices"][0]["message"].get("content") or ""
            return extract_jac(content), time.perf_counter() - t0
        except Exception:  # noqa: BLE001
            if attempt == 3:
                return None, time.perf_counter() - t0
            time.sleep(1.5 * (attempt + 1))
    return None, time.perf_counter() - t0


# --------------------------------------------------------------------------- #
# opencode CLI (agent-shaped; proofs only)
# --------------------------------------------------------------------------- #
def opencode_idiomize(floor_fn: str, py: str, entrypoint: str, model: str,
                      timeout: int = 150) -> tuple[str | None, float]:
    msg = build_prompt(floor_fn, py, entrypoint)
    t0 = time.perf_counter()
    try:
        p = subprocess.run(["opencode", "run", "--pure", "-m", model, msg],
                           capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return None, time.perf_counter() - t0
    return extract_jac(p.stdout), time.perf_counter() - t0


# --------------------------------------------------------------------------- #
# Over-generate + select (the MultiPL-T recipe: weak model, strong oracle).
#
# The paper ensures quality with volume + a test oracle, never a judge model
# (§4.3: 50 candidates/problem, keep test-passers, keep several diverse ones).
# We mirror that: sample k idiomize candidates at temperature; the CALLER runs
# each through `jac test` and keeps only passers. Idiom quality then enters as a
# FREE selection over the survivors (idiom_score, no extra LLM call) — because
# unlike the paper we have no idiom prior, so we prefer the passer that actually
# reached for Jac features. Cost stays one model per sample, exactly the paper's
# knob; nothing else is added.
# --------------------------------------------------------------------------- #
def zen_idiomize_k(floor_fn: str, py: str, entrypoint: str, k: int = 5,
                   model: str = "deepseek-v4-flash-free", temperature: float = 0.8,
                   max_tokens: int = 16384, timeout: float = 180
                   ) -> tuple[list[str], float]:
    """Sample k candidates at temperature. Returns (unique_candidates, total_s).

    Sequential per record — the batch harness parallelizes across records, and
    the free gateway rate-limits, so we keep in-record calls serial and let 429
    backoff (in zen_idiomize) absorb bursts. Deduplicates identical (whitespace-
    normalized) candidates so the oracle/selector don't re-test copies.
    """
    cands: list[str] = []
    seen: set[str] = set()
    total = 0.0
    for _ in range(k):
        jac, dt = zen_idiomize(floor_fn, py, entrypoint, model=model,
                               max_tokens=max_tokens, timeout=timeout,
                               temperature=temperature)
        total += dt
        if jac:
            norm = re.sub(r"\s+", "", jac)
            if norm not in seen:
                seen.add(norm)
                cands.append(jac)
    return cands, total


# --- free static idiom scorer (rubric proxy; NO model call) ----------------- #
# Ranks test-passing candidates by how much Jac idiom they use vs the floor.
# High-signal only: surviving Any/object is the dominant band-C tell; feature
# presence (match/comprehension/glob/startswith-tuple) is the reward. Behavior
# is already guaranteed by the test oracle, so this is a pure preference.
_ANY_OBJ = re.compile(r"(->\s*object\b|\bAny\b)")
_MATCH = re.compile(r"\bmatch\b")
_COMPREH = re.compile(r"\[[^\]\n]*\bfor\b[^\]\n]*\bin\b")
_GLOB = re.compile(r"\bglob\b")
_SW_TUPLE = re.compile(r"\.(?:startswith|endswith)\(\(")
_IF_EQ = re.compile(r"\bif\s+([A-Za-z_]\w*)\s*==")


def idiom_score(fn: str, floor_fn: str) -> float:
    """Relative idiom preference for a (behavior-verified) candidate. Higher = more idiomatic."""
    from collections import Counter
    if re.sub(r"\s+", "", fn) == re.sub(r"\s+", "", floor_fn):
        return -5.0                                   # cosmetic non-rewrite
    s = 0.0
    s -= 3.0 * len(_ANY_OBJ.findall(fn))              # D2: untyped boundary survives
    if _MATCH.search(fn):
        s += 2.0
    s += min(2, len(_COMPREH.findall(fn)))
    if _GLOB.search(fn):
        s += 1.0
    if _SW_TUPLE.search(fn):
        s += 1.0
    eq = Counter(_IF_EQ.findall(fn))                  # 3+ `if x == ...` = a match not taken
    if eq and max(eq.values()) >= 3:
        s -= 2.0
    return s
