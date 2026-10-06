"""AppealLetterGenerator walker — generates appeal letters for open disputes.

Walks Dispute nodes that are OPEN or IN_PROGRESS and generates formal
Medicare appeal letters via by llm(), attaching them as Appeal nodes.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.claim { Claim }
import from graph.nodes.line_item { LineItem }
import from graph.nodes.dispute { Dispute }
import from graph.nodes.appeal { Appeal }
import from abilities.llm_abilities { generate_appeal_letter }

import from datetime { datetime, timedelta }
import from uuid { uuid4 }

# Appeal deadlines: Level 1 = 120 days, Level 2 = 180 days
glob APPEAL_DEADLINES = {1: 120, 2: 180, 3: 60, 4: 90, 5: 60};
glob APPEAL_FORMS = {1: "CMS-20027", 2: "CMS-20033", 3: "ALJ-HEARING", 4: "MAC-REVIEW", 5: "DISTRICT-COURT"};
glob APPEAL_ADDRESSES = {
    1: "Medicare Administrative Contractor (MAC)",
    2: "Qualified Independent Contractor (QIC)",
    3: "Office of Medicare Hearings and Appeals (OMHA)",
    4: "Medicare Appeals Council (MAC-DAB)",
    5: "Federal District Court"
};
walker AppealLetterGenerator {
    has current_claim: any = None;

    has patient_name: str = "",
        patient_medicare_id: str = "",
        force_regenerate: bool = False;

    can start with Patient entry {
        self.patient_name = here.name;
        self.patient_medicare_id = here.medicare_id;
        visit [-->];
    }

    can process_claim with Claim entry {
        self.current_claim = here;
        visit [-->];
    }

    can process_line_item with LineItem entry {
        visit [-->];
    }

    can generate_for_dispute with Dispute entry {
        if here.status not in ["OPEN", "IN_PROGRESS"] {
            disengage;
        }

        # Check if there's already a pending appeal at this level
        existing_appeals = [a for a in [here-->] if isinstance(a, Appeal) and a.appeal_level == here.appeal_level + 1];
        if len(existing_appeals) > 0 and not self.force_regenerate {
            disengage;
        }

        next_level = here.appeal_level + 1 if here.appeal_level > 0 else 1;
        days_to_deadline = APPEAL_DEADLINES.get(next_level, 120);
        deadline = (datetime.utcnow() + timedelta(days=days_to_deadline)).strftime("%Y-%m-%d");

        # Get prior decision summaries
        prior_appeals = [a for a in [here-->] if isinstance(a, Appeal)];
        prior_decisions = [
            f"Level {a.appeal_level}: {a.decision} — {a.decision_rationale[:200]}"
            for a in prior_appeals if a.decision != "PENDING"
        ];

        # Generate the letter via LLM
        letter = generate_appeal_letter(
            dispute_description=here.description,
            error_type=here.error_type,
            amount_disputed=here.amount_disputed,
            patient_name=self.patient_name,
            patient_medicare_id=self.patient_medicare_id,
            claim_number=getattr(self, "current_claim", None) and self.current_claim.claim_number or "UNKNOWN",
            service_dates=getattr(self, "current_claim", None) and self.current_claim.service_date_start or "",
            provider_name="",
            cpt_code=here.error_type,
            denial_reason="\n".join(here.citations),
            appeal_level=next_level,
            prior_decision_summary="\n".join(prior_decisions) if prior_decisions else "No prior decisions"
        );

        appeal = Appeal(
            appeal_id=str(uuid4()),
            appeal_level=next_level,
            form_type=APPEAL_FORMS.get(next_level, "CMS-20027"),
            due_date=deadline,
            decision="PENDING",
            amount_requested=here.amount_disputed,
            letter_content=letter,
            submitted_to=APPEAL_ADDRESSES.get(next_level, "Medicare Administrative Contractor"),
            created_at=datetime.utcnow().isoformat()
        );
        here ++> appeal;
        here.status = "APPEALED";
        here.appeal_level = next_level;
        here.deadline = deadline;

        print(
            f"[AppealLetterGenerator] Generated Level {next_level} appeal "
            f"for dispute {here.dispute_id} (due {deadline})"
        );
    }
}
