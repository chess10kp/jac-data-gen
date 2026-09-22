#!/usr/bin/env python3
"""Stage 3 (LLM cleanup pass) for js2jac — fork of scripts/cursor_composer_batch.py.

Same batched cursor-agent driver (MCP stripped, ask-mode, process-group
teardown), but the prompt is the js2jac cleanup contract driven by
strip_policy.json instead of the py2jac idiomize seam.

Per record the model gets the React/TS SOURCE and (when the converter already
produced one) the FLOOR Jac, and must return ONE of:
  - a cleaned/idiomatic ```jac block  (strip + rewrite per policy), or
  - the literal token  REJECT  (lossy construct the policy says to drop)

Output contract for the guard: {id, candidate} JSONL, candidate omitted/"REJECT"
means dropped. ids are strings (repo__path), not ints.

faithful_mode (--faithful) promotes every fidelity:"lossy" policy entry to
reject — the single knob that switches the surface-syntax dataset (strip hard)
to the round-trip-faithful dataset (reject anything lossy).
"""
from __future__ import annotations
import argparse, json, re, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "lib"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
from composer_harness import run_composer, add_common_args

# Lives at the pkg root since the staged-layout refactor (no config/ dir).
POLICY_PATH = Path(__file__).resolve().parents[1] / "strip_policy.json"

# Deterministic pre-REJECT signals for floor_mode=none records (the LLM's most
# expensive, lowest-yield input: ~79% of a chunk, ~71% of which it rejects).
# High-precision only: a false pre-reject loses a real record forever.
_CSS_IN_JS = re.compile(
    r"\bstyled[\w.$]*(?:\s*\(|`)"  # styled.div`..`, styled(X), styled.div.attrs(..)`..`
    r"|\bcss`"                       # emotion/styled-components css template
    r"|makeStyles|createUseStyles|@emotion/|styled-components", re.I)

# Test/spec files: converter emits no convertible declarations (E7200) for
# them and the composer keeps almost none — validated on js2jac_20: only 2 of
# 315 kept records have a test-ish path (0.6% loss for a large token cut).
_TEST_PATH = re.compile(r"__tests?__/|\.spec\.|\.test\.|(^|/)tests?/", re.I)


def pre_reject(rec: dict, pol: dict, faithful: bool = False,
               css_always: bool = False) -> bool:
    """True => this record never needs the composer. Grounds:
    - CSS-in-JS source (E7205 dispatch 'reject' shapes): policy rejects the
      file only in FAITHFUL mode — in syntax mode the rule is strip-and-keep
      and the LLM really does salvage ~15% of them (measured js2jac_20:
      17/196 composer-kept records were CSS-in-JS), so extending this to
      syntax mode must be opted into via css_always (PREREJECT_CSS=1);
    - any converter error code whose policy action is reject (E7202/E7207/
      E7401 — per-FILE semantics, mode-independent), or faithful mode
      promoting any lossy code to reject.
    Codes with no policy entry keep the record in the LLM lane (conservative)."""
    if rec.get("floor_mode") not in (None, "none"):
        return False
    if _TEST_PATH.search(rec.get("path") or ""):
        return True
    if (faithful or css_always) and _CSS_IN_JS.search(rec.get("source_js") or ""):
        return True
    for code in rec.get("error_codes") or []:
        e = pol.get(code)
        if not e or code == "E7205":
            continue  # E7205 needs shape dispatch; regex covers its reject branch
        if e.get("action") == "reject" or (faithful and e.get("fidelity") == "lossy"):
            return True
    return False
GROUNDING_PATH = Path(__file__).resolve().parents[1] / "jac_grounding.md"

# string ids: everything up to the next ===ID or EOF
_BLOCK = re.compile(r"===ID\s+(.+?)===\s*(.*?)(?=(?:===ID\s+)|\Z)", re.S)
_FENCE = re.compile(r"```(?:jac)?\s*\n(.*?)```", re.S)
_REJECT = re.compile(r"^\s*REJECT\b", re.I)

# ---- Skill router -------------------------------------------------------
# The base grounding (jac_grounding.md = cheatsheet + types) covers universal
# syntax every hole needs. Beyond that, a hole only needs the topic guide for
# the construct it actually is. Route per record on cheap signals in its holes
# (regex over the hole codes + original JS the converter embedded, falling back
# to source), attach ONLY those guides, and tell each entry which apply. Guides
# are cached in jac_skills/ by gen_grounding.sh; a missing file is skipped.
SKILLS_DIR = Path(__file__).resolve().parents[1] / "jac_skills"
# topic -> compiled signal regex. Order = priority when capping.
_SKILL_SIGNALS = [
    ("jac-cl-components", re.compile(
        r"\buse(State|Effect|Ref|Callback|Memo|Context|Reducer)\b|React\.FC|"
        r"E7208|E7202|E7218|=>\s*\(?\s*<|JSX", re.I)),
    ("jac-cl-styling", re.compile(
        r"styled[\.(]|makeStyles|createUseStyles|css`|classNames?\b|clsx|"
        r"\bcn\(|tailwind|styled-components|@emotion", re.I)),
    ("jac-cl-routing", re.compile(
        r"useNavigate|useParams|useLocation|<Route\b|react-router|history\.push|"
        r"<Link\b|createBrowserRouter", re.I)),
    ("jac-cl-js-interop", re.compile(
        r"\bnew WebSocket|localStorage|sessionStorage|new Date\b|new URL\b|"
        r"CustomEvent|window\.|document\.|navigator\.", re.I)),
    ("jac-by-llm", re.compile(
        r"openai|anthropic|createChatCompletion|\bby llm\b|completions?\.create", re.I)),
    ("jac-has-fields", re.compile(
        r"createSlice|createContext|E7221|E7201|E7215|\binterface\b|"
        r"\benum\b|extraReducers", re.I)),
    # NOTE: no jac-npm-packages signal — a bare npm import is present in almost
    # every React/TS file, so it fires on everything and stops being signal.
]
_MAX_SKILLS = 3  # cap topics per entry; priority order above wins

# A hole rarely needs a whole 24KB topic — just the one section for its
# construct. Within a routed topic, select only the `##` sections whose sub-
# signal matches the entry (the intro, which carries the topic's core "cannot
# guess" idioms, is always included). Substrings match section headers loosely;
# a topic absent here (or an entry matching no sub-signal) falls back to the
# whole guide. Keep these aligned with the section headers in jac_skills/*.md.
_SECTION_SIGNALS: dict[str, list[tuple[str, "re.Pattern"]]] = {
    "jac-cl-components": [
        ("Props", re.compile(r"\bprops\b|React\.FC|interface\s+\w*Props", re.I)),
        ("Event types", re.compile(r"on(Click|Change|Submit|Input|KeyDown|Blur|Focus)\b", re.I)),
        ("Effects", re.compile(r"use(Effect|LayoutEffect)|cleanup|on mount|componentDidMount", re.I)),
        ("Statement slots", re.compile(r"\.map\(|&&\s*<|\?\s*<|conditional", re.I)),
    ],
    "jac-cl-js-interop": [
        ("new(", re.compile(r"\bnew\s+(WebSocket|URL|Date|CustomEvent|\w+)\(", re.I)),
        ("WebSocket", re.compile(r"WebSocket", re.I)),
        ("glob", re.compile(r"localStorage|sessionStorage|module.level", re.I)),
        ("CustomEvent", re.compile(r"CustomEvent|dispatchEvent", re.I)),
        ("Browser globals", re.compile(r"window\.|document\.|navigator\.", re.I)),
    ],
    "jac-cl-styling": [
        ("Scoped CSS", re.compile(r"css`|makeStyles|createUseStyles|styled[\.(]|@emotion", re.I)),
        ("cn()", re.compile(r"\bcn\(|clsx|classnames", re.I)),
        ("Conditional", re.compile(r"className=\{.*\?|conditional", re.I)),
        ("Tailwind", re.compile(r"tailwind|@apply", re.I)),
    ],
    "jac-cl-routing": [
        ("Navigation", re.compile(r"useNavigate|<Link\b|history\.push", re.I)),
        ("File-based", re.compile(r"<Route\b|createBrowserRouter|pages/", re.I)),
    ],
    "jac-has-fields": [
        ("postinit", re.compile(r"computed|derived|constructor", re.I)),
        ("Properties", re.compile(r"\bget\s+\w+\(|\bset\s+\w+\(|getter|setter", re.I)),
    ],
}
# _load_guide -> (intro_text, [(header, body), ...]); _SKILL_CACHE keyed by topic.
_SKILL_CACHE: dict[str, tuple[str, list[tuple[str, str]]]] = {}


def skills_for_record(rec: dict) -> list[str]:
    """Topic guides relevant to THIS record's holes. Empty for full-floor / no
    signal (base grounding still applies)."""
    if rec.get("floor_mode") == "full":
        return []
    hits = [topic for topic, rx in _SKILL_SIGNALS if rx.search(_route_text(rec))]
    return hits[:_MAX_SKILLS]


def _route_text(rec: dict) -> str:
    """Signal source: the hole region (codes + embedded original JS) if present,
    else the raw source."""
    floor = rec.get("floor_jac") or ""
    return floor if "JS2JAC-HOLE" in floor else rec.get("source_js", "")


def _load_guide(topic: str) -> tuple[str, list[tuple[str, str]]]:
    if topic not in _SKILL_CACHE:
        f = SKILLS_DIR / f"{topic}.md"
        if not f.exists():
            _SKILL_CACHE[topic] = ("", [])
        else:
            txt = f.read_text()
            head, _, rest = txt.partition("\n## ")
            secs: list[tuple[str, str]] = []
            if rest:
                for chunk in ("## " + rest).split("\n## "):
                    chunk = chunk.strip()
                    if not chunk:
                        continue
                    hdr = chunk.split("\n", 1)[0].lstrip("# ").strip()
                    secs.append((hdr, chunk if chunk.startswith("##") else "## " + chunk))
            _SKILL_CACHE[topic] = (head.strip(), secs)
    return _SKILL_CACHE[topic]


def _topic_slice(topic: str, rec: dict) -> str:
    """Intro + only the sections matching this record's sub-signals. Falls back
    to the whole guide when the topic has no section map or nothing matched."""
    intro, secs = _load_guide(topic)
    if not intro and not secs:
        return ""
    sig = _SECTION_SIGNALS.get(topic)
    if not sig or not secs:
        return "\n".join([intro] + [b for _, b in secs]).strip()
    text = _route_text(rec)
    wanted = {hdr_sub for hdr_sub, rx in sig if rx.search(text)}
    kept = [b for hdr, b in secs if any(w.lower() in hdr.lower() for w in wanted)]
    if not kept:  # topic matched but no specific section — give intro only
        return intro
    return "\n".join([intro] + kept).strip()


def batch_skill_section(recs: list[dict]) -> str:
    """For each topic any record needs, emit intro + the UNION of the sections
    those records' holes actually call for — deduped once per batch."""
    # topic -> {section_body: None} preserving insertion order; intro tracked once
    per_topic: dict[str, dict[str, None]] = {}
    intros: dict[str, str] = {}
    for r in recs:
        for t in skills_for_record(r):
            intro, _ = _load_guide(t)
            intros.setdefault(t, intro)
            sl = _topic_slice(t, r)
            # split slice back into intro + sections; store sections by body
            body = sl[len(intro):].strip() if sl.startswith(intro) else sl
            for sec in filter(None, (s.strip() for s in body.split("\n## "))):
                key = sec if sec.startswith("##") else "## " + sec
                per_topic.setdefault(t, {})[key] = None
    if not per_topic and not intros:
        return ""
    parts = ["\n\n===== RELEVANT JAC SKILLS (only the sections these holes need) =====\n"]
    for t in intros:
        parts.append(f"\n--- skill: {t} ---\n{intros[t]}\n")
        for sec in per_topic.get(t, {}):
            parts.append(f"\n{sec}\n")
    parts.append("\n===== END JAC SKILLS =====\n")
    return "".join(parts)


def build_system_prompt(faithful: bool, grounded: bool = True) -> str:
    """Compact hard rules + the strip policy rendered as an action table.

    `grounded` injects the ~21KB Jac reference. It is only worth its tokens when
    the model must GENERATE Jac without a full exemplar (floor_mode none/holes);
    for a FULL floor the floor already is the exemplar, so the caller passes
    grounded=False and the batch runs lean. Decided per batch in call_agent.
    """
    pol = json.loads(POLICY_PATH.read_text())
    lines: list[str] = []
    for code, e in pol.items():
        if code.startswith("_"):
            continue
        if code == "E7205":
            lines.append(f"{code} (const-init wall) — dispatch on what the export initializes to:")
            for shape, d in e["dispatch"].items():
                act = "reject" if (faithful and d["fidelity"] == "lossy") else d["action"]
                lines.append(f"    - {shape}: {act.upper()} — {d['rule']}")
            continue
        act = "reject" if (faithful and e.get("fidelity") == "lossy") else e["action"]
        lines.append(f"{code} {e.get('msg','')} — {act.upper()}: {e['rule']}")
    policy_txt = "\n".join(lines)
    mode = ("FAITHFUL mode: anything that would drop real behavior => REJECT."
            if faithful else
            "SYNTAX mode: strip lossy constructs and keep the file convertible.")
    # Authoritative Jac reference, injected so the model grounds on real Jac
    # idiom rather than hallucinating (Jac is new and thin in pretraining). Kept
    # in a versioned file, regenerated from `jac guide` by gen_grounding.sh.
    grounding = ""
    if grounded and GROUNDING_PATH.exists():
        grounding = ("\n\n===== JAC LANGUAGE REFERENCE (authoritative) =====\n"
                     + GROUNDING_PATH.read_text()
                     + "\n===== END JAC REFERENCE =====\n")
    return f"""You are an expert Jac (Jaseci Labs) engineer cleaning up machine-converted
React/TypeScript so it becomes valid, idiomatic Jac for a translation dataset.
{grounding}
You get, per record: the original TS/React SOURCE and, when the converter
already produced one, the FLOOR Jac. The FLOOR comes in two shapes:
  - FULL floor — valid Jac; idiomize it, keep exported names EXACTLY.
  - SCAFFOLD+HOLES floor — valid Jac scaffold with `# JS2JAC-HOLE[code]`
    comments marking declarations the converter could not lower (the original
    JS follows each hole). KEEP the scaffold declarations as-is; convert ONLY
    the holes into idiomatic Jac in place, and you MAY add concrete types or
    small stubs so the filled-in code resolves. Never delete a hole's intent to
    make it pass — if a hole is genuinely unmodelable, REJECT the whole record.
When there is no FLOOR, the file failed to convert entirely: apply the policy
below to strip/rewrite it into convertible Jac.

{mode}

For EACH record output EXACTLY, in order:
===ID <id>===
```jac
<cleaned jac>
```
or, if the policy says this file/construct must be dropped:
===ID <id>===
REJECT

HARD RULES (any violation discards that record):
1. VALID JAC ONLY — braces {{ }} and semicolons ;, never Python colon-indent.
   (match/case bodies are the one indent exception — see the reference.)
2. Keep exported component/function names EXACTLY.
3. NEVER emit `any`; infer concrete types.
4. Leave NO `# JS2JAC-HOLE` comments in the output — every hole is either
   converted to real Jac or the record is REJECTed.
5. Output nothing but the ===ID blocks (fenced jac or REJECT). No prose.

CLEANUP POLICY (by converter error / construct):
{policy_txt}
"""




def _extract(seg: str) -> str | None:
    if _REJECT.match(seg):
        return "REJECT"
    m = _FENCE.search(seg)
    return m.group(1).strip() if m else None


def parse_result(text: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for m in _BLOCK.finditer(text or ""):
        code = _extract(m.group(2))
        if code:
            out[m.group(1).strip()] = code
    return out


def build_prompt(recs: list[dict]) -> str:
    parts = ["Clean up EACH record below per the policy.\n"]
    for r in recs:
        floor = r.get("floor_jac")
        skills = skills_for_record(r)
        skill_ptr = (f"  [relevant Jac skills: {', '.join(skills)}]" if skills else "")
        # FULL floor is its own complete exemplar; the source is only context for
        # intent, so cap it tighter (the 3500-char source was ~half the payload).
        full = bool(floor) and "JS2JAC-HOLE" not in floor
        src = (r.get("source_js") or "")[: (1500 if full else 3500)]
        note = " (truncated — FLOOR is the authoritative full conversion)" if full and len(r.get("source_js") or "") > 1500 else ""
        parts.append(f"\n===ID {r['id']}===  (status: {r['status']}){skill_ptr}\n"
                     f"SOURCE{note}:\n{src}\n")
        # ORM file: hand the model the repo's lifted graph schema + traversal digest
        # so it rewrites prisma.x.find/create/update into walkers/traversals over
        # these real nodes+edges — NOT a hollow `return []` stub (which the
        # behavioral gate rejects anyway).
        if r.get("schema_jac"):
            digest = r.get("schema_digest") or ""
            parts.append(
                "\nGRAPH SCHEMA (this app's Prisma models lifted to Jac node/edge "
                "archetypes — DO NOT redeclare; write against them). MANDATORY: rewrite "
                "EVERY `prisma.*` call as a graph op — findMany->`[root -->[?:Model]]`, "
                "findUnique/findFirst(where)->filtered traversal `[root -->[?:Model, f==v]]`, "
                "create->`root ++> Model(...)` (or `owner +>:Edge:+> Model(...)`), "
                "update->resolve node then mutate in place (auto-persists), "
                "delete->`del <node>`, relation->typed edge traversal `[u ->:Edge:->]`. "
                "PREFER a `walker:pub` with `can ... with Root/<Node> entry` invoked by "
                "`root spawn W()` (the idiomatic endpoint shape) over a plain def. "
                "If ANY `prisma.` token remains in your output the record is worthless — "
                "rewrite it fully or REJECT:\n"
                f"{r['schema_jac']}\n{digest}\n")
        if floor and "JS2JAC-HOLE" in floor:
            parts.append("\nFLOOR (SCAFFOLD+HOLES — keep scaffold, convert the "
                         "# JS2JAC-HOLE holes in place, or REJECT):\n"
                         f"{floor[:3500]}\n")
        elif floor:
            parts.append(f"\nFLOOR (FULL valid Jac — idiomize, do not reject):\n{floor[:2500]}\n")
        else:
            parts.append("\nFLOOR: (none — converter rejected this file; strip/rewrite or REJECT)\n")
    return "".join(parts)


def _needs_grounding(recs: list[dict]) -> bool:
    """Grounding is only worth its ~21KB when a record makes the model generate
    Jac without a full exemplar. A FULL floor is its own exemplar; anything else
    (none = freestyle from source, holes = write the hole bodies) needs it."""
    return any(r.get("floor_mode", "none") != "full" for r in recs)


def main() -> int:
    ap = argparse.ArgumentParser()
    add_common_args(ap)
    ap.add_argument("--faithful", action="store_true",
                    help="promote every lossy strip to reject (round-trip dataset)")
    args = ap.parse_args()

    # Build both once; sysprompt_for picks per batch so full-floor idiomize
    # batches skip the ~21KB Jac reference (the floor already grounds them).
    sysprompts = {
        "grounded": build_system_prompt(args.faithful, grounded=True),
        "lean": build_system_prompt(args.faithful, grounded=False),
    }

    def sysprompt_for(recs: list[dict]) -> str:
        return sysprompts["grounded"] if _needs_grounding(recs) else sysprompts["lean"]

    return run_composer("js2jac-composer", args, build_prompt, parse_result,
                        sysprompt_for=sysprompt_for)


if __name__ == "__main__":
    sys.exit(main())
