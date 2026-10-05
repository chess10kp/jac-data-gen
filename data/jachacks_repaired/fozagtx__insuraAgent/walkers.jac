# walkers.jac — REST surface.
#
# `jac serve walkers.jac` exposes each walker as a POST endpoint at
# /walker/<name>. The `has` fields become the JSON request body.

import json;
import uuid;
import datetime;

import from models { Claim, Policy, Appeal, DenialReason, AppealStrength, Contradiction }
import from tools {
    extract_denial_reason,
    extract_relevant_clauses,
    find_contradictions,
    assess_appeal_strength,
    draft_appeal_letter
}


# ---- Walker: full agentic pipeline -------------------------------------
#
# POST /walker/submit_claim
# Body: {
#   "patient_name": "...",
#   "member_id": "...",
#   "claim_number": "...",
#   "date_of_service": "YYYY-MM-DD",
#   "cpt_code": "...",
#   "billed_amount": 0.0,
#   "plan_name": "...",
#   "denial_text": "...",
#   "policy_text": "...",
#   "clinical_record": ""        # optional
# }

walker:pub submit_claim {
    has patient_name: str;
    has member_id: str;
    has claim_number: str;
    has date_of_service: str;
    has cpt_code: str;
    has billed_amount: float;
    has plan_name: str;
    has denial_text: str;
    has policy_text: str;
    has clinical_record: str = "";

    can run with Root entry {
        # 1. Persist the inputs on the graph so the appeal can reference
        #    them later. Connecting to root makes Jac auto-persist.
        claim = Claim(
            claim_id=self.claim_number,
            patient_name=self.patient_name,
            member_id=self.member_id,
            cpt_code=self.cpt_code,
            date_of_service=self.date_of_service,
            billed_amount=self.billed_amount,
            denial_text=self.denial_text,
            clinical_record=self.clinical_record
        );
        policy = Policy(
            policy_id=f"POL-{self.member_id}",
            plan_name=self.plan_name,
            full_text=self.policy_text
        );
        here ++> claim;
        here ++> policy;

        # 2. Run the 5 tools sequentially (Featherless can't handle the
        #    agentic ReAct loop — same compromise as main.jac).
        reason = extract_denial_reason(self.denial_text);
        clauses = extract_relevant_clauses(self.policy_text, reason);
        contradictions = find_contradictions(self.denial_text, self.clinical_record, clauses);
        strength = assess_appeal_strength(contradictions);
        letter = draft_appeal_letter(
            patient_name=self.patient_name,
            member_id=self.member_id,
            claim_number=self.claim_number,
            date_of_service=self.date_of_service,
            cpt_code=self.cpt_code,
            billed_amount=self.billed_amount,
            plan_name=self.plan_name,
            denial_reason=reason,
            contradictions=contradictions,
            clinical_record=self.clinical_record
        );

        # 3. Persist the resulting Appeal.
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
        here ++> appeal;

        report {
            "appeal_id": appeal.appeal_id,
            "claim_id": claim.claim_id,
            "subject": letter.subject,
            "letter": appeal.letter_body,
            "citations": letter.citations
        };
    }
}


# ---- Walker: list all appeals on the graph -----------------------------
#
# POST /walker/list_appeals
# Body: {}

walker:pub list_appeals {
    can run with Root entry {
        appeals = [-->[?:Appeal]];
        rows = [];
        for a in appeals {
            rows.append({
                "appeal_id": a.appeal_id,
                "claim_id": a.claim_id,
                "subject": a.letter_subject,
                "created_at": a.created_at
            });
        }
        report rows;
    }
}
