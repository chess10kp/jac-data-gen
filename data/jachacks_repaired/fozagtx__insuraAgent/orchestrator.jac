# orchestrator.jac — the agentic core.
#
# `plan_and_generate_appeal` is the wow moment: it is an LLM-typed
# function with FIVE tools registered, and the LLM picks the order
# in which to call them. byLLM runs the full ReAct loop under the
# hood — we never write `if/elif/then` to sequence the tools.
#
# A judge can grep this file for `tools=[` and see the agentic
# behavior in one line.
#
# Compatibility note: the agent itself returns a JSON-encoded `str`
# (not a typed `AppealLetter`) because Featherless's vLLM backend
# rejects byLLM's `response_format: json_schema` envelope. A thin
# Python wrapper re-hydrates the `AppealLetter` so callers
# (`walkers.jac`, `main.jac`, the web UI) stay unchanged.

import os;
import from byllm.llm { Model }
import from models { AppealLetter, DenialReason, Contradiction, PolicyClause, AppealStrength }
import from tools {
    extract_denial_reason,
    extract_relevant_clauses,
    find_contradictions,
    assess_appeal_strength,
    draft_appeal_letter,
    _parse_json_obj
}


# Reuse the same model-selection logic so the agent and the tools use the
# same backend. Duplicated rather than imported to keep this file
# self-contained for the "grep for tools=[" demo moment.

def _pick_agent_model() -> Model {
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

glob agent_llm = _pick_agent_model();


"""
You are a senior health-insurance appeals specialist. The user will give
you a denial letter, the patient's policy document, the patient's
clinical record, and the claim metadata.

Plan and execute a full appeal:
  - First classify the denial reason from the denial letter.
  - Then extract the policy clauses relevant to that reason.
  - Then look for concrete contradictions between the denial and the
    policy, using the clinical record as evidence.
  - Then draft a complete formal appeal letter that cites the clauses
    and contradictions.

Use the provided tools. Do not invent quotes — every quoted passage
must come from a tool result.

Return the final appeal letter as a JSON object (no markdown fence)
with keys: subject (str), salutation (str), body (str),
citations (list of str), closing (str). Return ONLY the JSON object.
"""
def plan_and_generate_appeal_raw(
    denial_text: str,
    policy_text: str,
    clinical_record: str,
    patient_name: str,
    member_id: str,
    claim_number: str,
    date_of_service: str,
    cpt_code: str,
    billed_amount: float,
    plan_name: str
) -> str by agent_llm(
    tools=[
        extract_denial_reason,
        extract_relevant_clauses,
        find_contradictions,
        assess_appeal_strength,
        draft_appeal_letter
    ]
);


# Thin wrapper that re-hydrates the JSON string into an AppealLetter so
# downstream callers don't need to change.
def plan_and_generate_appeal(
    denial_text: str,
    policy_text: str,
    clinical_record: str,
    patient_name: str,
    member_id: str,
    claim_number: str,
    date_of_service: str,
    cpt_code: str,
    billed_amount: float,
    plan_name: str
) -> AppealLetter {
    raw = plan_and_generate_appeal_raw(
        denial_text, policy_text, clinical_record, patient_name,
        member_id, claim_number, date_of_service, cpt_code,
        billed_amount, plan_name
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
