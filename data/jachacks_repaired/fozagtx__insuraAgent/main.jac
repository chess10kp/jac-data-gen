# main.jac — end-to-end CLI demo.
#
#   jac run main.jac
#
# Reads the bundled sample claim, runs the agent's 5 tools in sequence,
# and prints the resulting appeal letter.
#
# Note: the agentic orchestrator (`orchestrator.jac::plan_and_generate_appeal`)
# still exists and is what walkers.jac + the REST API expose — the LLM
# picks tool order via `by llm(tools=[...])`. We use a sequential
# tool pipeline here because Featherless's tool-calling support adds
# significant latency to multi-turn ReAct loops, and a 60-second demo
# matters more than the per-call autonomy. Same tools, same outputs.

import os;
import json;
import time;
import uuid;
import datetime;

import from models { Claim, Policy, Appeal, DenialReason, AppealStrength }
import from tools {
    extract_denial_reason,
    extract_relevant_clauses,
    find_contradictions,
    assess_appeal_strength,
    draft_appeal_letter
}


def _read(path: str) -> str {
    with open(path, "r") as f {
        return f.read();
    }
}


def _check_keys() -> bool {
    have_featherless = (os.environ.get("FEATHERLESS_API_KEY", "") != ""
                        or os.environ.get("FEATHERLESS_AI_API_KEY", "") != "");
    have_anthropic   = os.environ.get("ANTHROPIC_API_KEY", "") != "";
    have_gemini      = os.environ.get("GEMINI_API_KEY", "") != "";
    have_openai      = os.environ.get("OPENAI_API_KEY", "") != "";
    if not (have_featherless or have_anthropic or have_gemini or have_openai) {
        print("=" * 72);
        print("ERROR: No LLM API key found in environment.");
        print("  export FEATHERLESS_API_KEY=fl-...      (default, Featherless)");
        print("=" * 72);
        return False;
    }
    return True;
}


def _banner(title: str) {
    print("");
    print("=" * 72);
    print(title);
    print("=" * 72);
}


def _step(num: int, label: str) -> float {
    print("");
    print(f"  [step {num}/5] {label} ...");
    return time.time();
}


def _done(t0: float) {
    dt = time.time() - t0;
    print(f"           done in {dt:.1f}s");
}


with entry {
    if not _check_keys() {
        # exit cleanly
    } else {
        # ---- 1. Load sample inputs ------------------------------------
        denial_text     = _read("samples/denial_001.txt");
        policy_text     = _read("samples/policy_001.txt");
        clinical_record = _read("samples/patient_record_001.txt");

        _banner("INSURANCE APPEAL AGENT  -  CLI DEMO");
        print("Sample claim:        CLM-2026-0418-9921");
        print("CPT code:            95810 (in-lab polysomnography)");
        print("Billed amount:       $3,847.00");
        print("Plan:                BlueShield PPO Gold 2026");
        print("Denial reason given: Not medically necessary");
        print("");
        print("The agent has 5 tools. Each one is a `def ... by llm()`");
        print("call in tools.jac. Watch them run.");

        # ---- 2. Persist Claim + Policy on root graph ------------------
        claim = Claim(
            claim_id="CLM-2026-0418-9921",
            patient_name="Jordan A. Reyes",
            member_id="BSH-44892-01",
            cpt_code="95810",
            date_of_service="2026-04-18",
            billed_amount=3847.00,
            denial_text=denial_text,
            clinical_record=clinical_record
        );
        policy = Policy(
            policy_id="POL-BSH-44892-01",
            plan_name="BlueShield PPO Gold 2026",
            full_text=policy_text
        );
        root ++> claim;
        root ++> policy;

        wall_start = time.time();

        # ---- 3. The 5 tool calls --------------------------------------
        t = _step(1, "classify the denial reason");
        reason = extract_denial_reason(denial_text);
        print(f"           -> {reason}");
        _done(t);

        t = _step(2, "extract relevant policy clauses");
        clauses = extract_relevant_clauses(policy_text, reason);
        print(f"           -> {len(clauses)} clauses extracted");
        _done(t);

        t = _step(3, "find contradictions between denial and policy");
        contradictions = find_contradictions(denial_text, clinical_record, clauses);
        print(f"           -> {len(contradictions)} contradictions found");
        _done(t);

        t = _step(4, "assess overall appeal strength");
        strength = assess_appeal_strength(contradictions);
        print(f"           -> {strength}");
        _done(t);

        t = _step(5, "draft the appeal letter");
        letter = draft_appeal_letter(
            patient_name="Jordan A. Reyes",
            member_id="BSH-44892-01",
            claim_number="CLM-2026-0418-9921",
            date_of_service="2026-04-18",
            cpt_code="95810",
            billed_amount=3847.00,
            plan_name="BlueShield PPO Gold 2026",
            denial_reason=reason,
            contradictions=contradictions,
            clinical_record=clinical_record
        );
        _done(t);

        total_dt = time.time() - wall_start;

        # ---- 4. Persist Appeal node -----------------------------------
        appeal = Appeal(
            appeal_id=f"APL-{uuid.uuid4().hex[:8]}",
            claim_id=claim.claim_id,
            policy_id=policy.policy_id,
            denial_reason=reason,
            strength=strength,
            contradictions_json=json.dumps(
                [{"denial_quote": c.denial_quote,
                  "policy_quote": c.policy_quote,
                  "clause_section": c.clause_section,
                  "explanation": c.explanation} for c in contradictions]
            ),
            letter_subject=letter.subject,
            letter_body=f"{letter.salutation}\n\n{letter.body}\n\n{letter.closing}",
            citations_json=json.dumps(letter.citations),
            created_at=datetime.datetime.utcnow().isoformat()
        );
        root ++> appeal;

        # ---- 5. Render -------------------------------------------------
        _banner("GENERATED APPEAL LETTER");
        print(f"Subject: {letter.subject}");
        print("");
        print(letter.salutation);
        print("");
        print(letter.body);
        print("");
        print(letter.closing);

        _banner("CITATIONS");
        for c in letter.citations {
            print(f"  - {c}");
        }

        _banner("PERSISTED ON GRAPH");
        print(f"  Appeal ID:  {appeal.appeal_id}");
        print(f"  Claim ID:   {appeal.claim_id}");
        print(f"  Policy ID:  {appeal.policy_id}");
        print(f"  Created at: {appeal.created_at}");
        print("");
        print(f"  Total agent time: {total_dt:.1f}s across 5 tool calls");
        print("(Nodes persist on root and survive subsequent `jac run`s.)");
    }
}
