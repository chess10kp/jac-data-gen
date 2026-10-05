# tools.jac — the four agentic tools the orchestrator can call.
#
# Each tool is an LLM-typed Jac function. Originally these returned typed
# `obj` / `list[obj]` values, but byLLM emits OpenAI-style
# `response_format: {"type": "json_schema", ...}` for those returns, and
# Featherless's vLLM backend rejects that envelope (for both
# `featherless_ai/` and `openai/` routes). So the three high-risk tools
# now return JSON-encoded `str` from the LLM and are re-hydrated to the
# original typed objects in Python — public signatures are unchanged so
# `orchestrator.jac`, `walkers.jac`, `main.jac`, and the web UI keep
# working untouched. Enum returns round-trip fine and stay as-is.
#
# See FEATHERLESS_COMPAT.md for the full rationale.

import os;
import json;
import re;
import from byllm.llm { Model }
import from models { DenialReason, PolicyClause, Contradiction, AppealLetter, AppealStrength }


# -------------------- model selection --------------------
# Preference order:
#   1. FEATHERLESS_API_KEY -> Qwen2.5-14B via OpenAI-compat route (free demo)
#   2. ANTHROPIC_API_KEY   -> Claude Sonnet 4
#   3. GEMINI_API_KEY      -> Gemini 2.5 Flash
#   4. OPENAI_API_KEY      -> gpt-4o-mini
#
# Featherless is OpenAI-compatible — `run_demo.sh` re-exports
# OPENAI_API_KEY / OPENAI_API_BASE so LiteLLM routes correctly. Override
# the Featherless model via APPEAL_MODEL (e.g. a smaller, cheaper model
# for iteration).

def _pick_model() -> Model {
    if os.environ.get("FEATHERLESS_API_KEY") {
        model_id = os.environ.get(
            "APPEAL_MODEL", "openai/Qwen/Qwen2.5-14B-Instruct"
        );
        return Model(
            model_name=model_id,
            api_key=os.environ.get("FEATHERLESS_API_KEY", "")
        );
    }
    if os.environ.get("ANTHROPIC_API_KEY") {
        return Model(model_name="claude-sonnet-4-20250514");
    }
    if os.environ.get("GEMINI_API_KEY") {
        return Model(model_name="gemini/gemini-2.5-flash");
    }
    if os.environ.get("OPENAI_API_KEY") {
        return Model(model_name="gpt-4o-mini");
    }
    raise Exception(
        "No LLM API key found. Set one of: FEATHERLESS_API_KEY (recommended), "
        "ANTHROPIC_API_KEY, GEMINI_API_KEY, OPENAI_API_KEY."
    );
}

glob llm = _pick_model();


# -------------------- JSON parsing helpers --------------------
# Models sometimes wrap JSON in prose or markdown fences. These helpers
# strip that and best-effort-parse the first balanced JSON object/array.

def _parse_json_obj(s: str) -> dict {
    if not s {
        return {} ;
    }
    txt = s.strip();
    m = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", txt, re.DOTALL);
    if m {
        txt = m.group(1);
    } else {
        start = txt.find("{");
        if start == -1 {
            return {} ;
        }
        depth = 0;
        end = -1;
        i = start;
        while i < len(txt) {
            ch = txt[i];
            if ch == "{" {
                depth += 1;
            } elif ch == "}" {
                depth -= 1;
                if depth == 0 {
                    end = i;
                    break;
                }
            }
            i += 1;
        }
        if end == -1 {
            return {} ;
        }
        txt = txt[start:end+1];
    }
    try {
        return json.loads(txt);
    } except Exception as e {
        return {} ;
    }
}

def _parse_json_list(s: str) -> list {
    if not s {
        return [] ;
    }
    txt = s.strip();
    m = re.search(r"```(?:json)?\s*(\[.*?\])\s*```", txt, re.DOTALL);
    if m {
        txt = m.group(1);
    } else {
        start = txt.find("[");
        if start == -1 {
            return [] ;
        }
        depth = 0;
        end = -1;
        i = start;
        while i < len(txt) {
            ch = txt[i];
            if ch == "[" {
                depth += 1;
            } elif ch == "]" {
                depth -= 1;
                if depth == 0 {
                    end = i;
                    break;
                }
            }
            i += 1;
        }
        if end == -1 {
            return [] ;
        }
        txt = txt[start:end+1];
    }
    try {
        return json.loads(txt);
    } except Exception as e {
        return [] ;
    }
}


# ---- TOOL 1: classify the denial reason ---------------------------------
# Was an enum return — Featherless/vLLM rejects byLLM's empty json_schema
# envelope on enums same as on typed objs, so we return a plain str and
# match it to the enum in Python.

"""
Read a health-insurance denial letter and identify the single primary reason
the claim was denied. Return EXACTLY ONE of these strings (uppercase, no
quotes, no extra text):

  NOT_MEDICALLY_NECESSARY
  OUT_OF_NETWORK
  PRIOR_AUTH_MISSING
  EXPERIMENTAL_OR_INVESTIGATIONAL
  CODING_ERROR
  BENEFIT_EXCLUSION
  OTHER

Be conservative: pick OTHER if the letter does not clearly fit one of the
named categories.
"""
def extract_denial_reason_raw(denial_text: str) -> str by llm();

def extract_denial_reason(denial_text: str) -> DenialReason {
    raw = extract_denial_reason_raw(denial_text).strip().upper();
    if "NOT_MEDICALLY_NECESSARY" in raw { return DenialReason.NOT_MEDICALLY_NECESSARY; }
    if "OUT_OF_NETWORK" in raw { return DenialReason.OUT_OF_NETWORK; }
    if "PRIOR_AUTH" in raw { return DenialReason.PRIOR_AUTH_MISSING; }
    if "EXPERIMENTAL" in raw or "INVESTIGATIONAL" in raw { return DenialReason.EXPERIMENTAL_OR_INVESTIGATIONAL; }
    if "CODING" in raw { return DenialReason.CODING_ERROR; }
    if "BENEFIT_EXCLUSION" in raw or "EXCLUSION" in raw { return DenialReason.BENEFIT_EXCLUSION; }
    return DenialReason.OTHER;
}


# ---- TOOL 2: extract the policy clauses relevant to that reason ---------
# Originally returned `list[PolicyClause]`. Now returns a JSON-string from
# the LLM and is parsed back into `list[PolicyClause]` in Python so the
# public signature stays the same.

"""
Given the full text of an insurance policy and a known denial reason,
extract every clause that bears on whether the denial is correct.
Include the section number (e.g. "7.2(i)"), a short title, the verbatim
clause text, and a one-sentence note on why it is relevant.

Return a JSON array (no markdown fence). Each element must be an object
with keys: section (str), title (str), text (str), relevance_note (str).
Return AT MOST 6 elements, ranked by relevance. Return ONLY the JSON array.
"""
def extract_relevant_clauses_raw(
    policy_text: str,
    denial_reason: DenialReason
) -> str by llm();

def extract_relevant_clauses(
    policy_text: str,
    denial_reason: DenialReason
) -> list[PolicyClause] {
    raw = extract_relevant_clauses_raw(policy_text, denial_reason);
    out = [];
    for d in _parse_json_list(raw) {
        if not isinstance(d, dict) {
            continue;
        }
        out.append(PolicyClause(
            section=str(d.get("section", "")),
            title=str(d.get("title", "")),
            text=str(d.get("text", "")),
            relevance_note=str(d.get("relevance_note", ""))
        ));
    }
    return out;
}


# ---- TOOL 3: find concrete contradictions between denial and policy -----
# Same story — JSON-string return, Python re-hydration.

"""
Given the denial letter, the patient's clinical record, and the relevant
policy clauses, identify every concrete contradiction or unmet requirement
that supports overturning the denial. For each contradiction, quote the
exact denial language, quote the exact policy language, cite the clause
section, and explain in one sentence why the denial conflicts with the
plan's own rules.

If no contradictions exist, return an empty array — do not invent them.

Return a JSON array (no markdown fence). Each element: denial_quote (str),
policy_quote (str), clause_section (str), explanation (str). Return ONLY
the JSON array.
"""
def find_contradictions_raw(
    denial_text: str,
    clinical_record: str,
    clauses: list[PolicyClause]
) -> str by llm();

def find_contradictions(
    denial_text: str,
    clinical_record: str,
    clauses: list[PolicyClause]
) -> list[Contradiction] {
    raw = find_contradictions_raw(denial_text, clinical_record, clauses);
    out = [];
    for d in _parse_json_list(raw) {
        if not isinstance(d, dict) {
            continue;
        }
        out.append(Contradiction(
            denial_quote=str(d.get("denial_quote", "")),
            policy_quote=str(d.get("policy_quote", "")),
            clause_section=str(d.get("clause_section", "")),
            explanation=str(d.get("explanation", ""))
        ));
    }
    return out;
}


# ---- TOOL 4: assess appeal strength ------------------------------------
# Was an enum return — same Featherless schema bug. Now str + parse.

"""
Based on the contradictions found, classify how strong the appeal is.
Return EXACTLY ONE of these strings (uppercase, no quotes, no extra text):

  WEAK
  MODERATE
  STRONG
  VERY_STRONG

STRONG/VERY_STRONG requires multiple clearly-cited contradictions backed
by clinical evidence.
"""
def assess_appeal_strength_raw(
    contradictions: list[Contradiction]
) -> str by llm();

def assess_appeal_strength(
    contradictions: list[Contradiction]
) -> AppealStrength {
    raw = assess_appeal_strength_raw(contradictions).strip().upper();
    if "VERY_STRONG" in raw or "VERY STRONG" in raw { return AppealStrength.VERY_STRONG; }
    if "STRONG" in raw { return AppealStrength.STRONG; }
    if "WEAK" in raw { return AppealStrength.WEAK; }
    return AppealStrength.MODERATE;
}


# ---- TOOL 5: compose the actual appeal letter --------------------------
# Originally returned `AppealLetter`. Now JSON-string + Python re-hydration.

"""
Compose a professional, formal first-level internal appeal letter from
the patient to the insurer's appeals department. The letter must:

  1. Open by clearly identifying the claim (claim number, date of
     service, CPT code, billed amount, member ID).
  2. State that the patient is filing a first-level internal appeal
     under the plan's appeals procedure.
  3. For each contradiction provided, walk through it: quote the
     denial's reasoning, quote the relevant policy clause with its
     section number, and explain why the denial is inconsistent with
     the plan's own rules.
  4. Reference any supporting clinical facts from the patient record.
  5. Request a specific remedy: reversal of the denial and payment
     of the claim within the plan's stated 30-day appeal-decision
     window.
  6. Close professionally with a signature block.

The `citations` field must be a flat list of strings, each citing one
plan section or clinical document (e.g. "Plan Section 7.2(i)",
"Clinical note dated 2026-04-10").

Tone: firm, professional, evidence-based. Do not threaten. Do not
sound robotic.

Return a JSON object (no markdown fence) with keys: subject (str),
salutation (str), body (str), citations (list of str), closing (str).
Return ONLY the JSON object.
"""
def draft_appeal_letter_raw(
    patient_name: str,
    member_id: str,
    claim_number: str,
    date_of_service: str,
    cpt_code: str,
    billed_amount: float,
    plan_name: str,
    denial_reason: DenialReason,
    contradictions: list[Contradiction],
    clinical_record: str
) -> str by llm();

def draft_appeal_letter(
    patient_name: str,
    member_id: str,
    claim_number: str,
    date_of_service: str,
    cpt_code: str,
    billed_amount: float,
    plan_name: str,
    denial_reason: DenialReason,
    contradictions: list[Contradiction],
    clinical_record: str
) -> AppealLetter {
    raw = draft_appeal_letter_raw(
        patient_name, member_id, claim_number, date_of_service,
        cpt_code, billed_amount, plan_name, denial_reason,
        contradictions, clinical_record
    );
    d = _parse_json_obj(raw);
    cites = d.get("citations") or [];
    if not isinstance(cites, list) {
        cites = [str(cites)];
    }
    return AppealLetter(
        subject=str(d.get("subject", "")),
        salutation=str(d.get("salutation", "")),
        body=str(d.get("body", "")),
        citations=[str(c) for c in cites],
        closing=str(d.get("closing", ""))
    );
}
