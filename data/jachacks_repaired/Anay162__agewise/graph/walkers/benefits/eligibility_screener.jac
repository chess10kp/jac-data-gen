"""EligibilityScreener walker — screens patient against benefit program criteria."""

import from graph.nodes.patient { Patient }
import from graph.nodes.benefits_eligibility { BenefitsEligibility }
import from abilities.llm_abilities { screen_benefits_eligibility }
import from datetime { datetime }
import from uuid { uuid4 }

glob BENEFIT_PROGRAMS: list[str] = [
    "EXTRA_HELP",
    "QMB",
    "SLMB",
    "SNAP",
    "LIHEAP",
    "MEDICARE_SAVINGS_PROGRAM",
    "STATE_PHARMACEUTICAL_ASSISTANCE",
    "MEDICAID",
    "VETERANS_BENEFITS",
    "SUPPLEMENTAL_SECURITY_INCOME"
];

walker EligibilityScreener {
    has monthly_income: float = 0.0,
        total_assets: float = 0.0,
        eligible_count: int = 0;

    can screen with Patient entry {
        already_screened = {n.program_type for n in [here-->] if isinstance(n, BenefitsEligibility)};

        for program in BENEFIT_PROGRAMS {
            if program in already_screened {
                continue;
            }
            result = screen_benefits_eligibility(
                program=program,
                state=here.state,
                estimated_monthly_income=self.monthly_income,
                estimated_assets=self.total_assets,
                has_medicare=here.medicare_id != "",
                has_medicaid=here.medicaid_id != "",
                age=0
            );
            elig = BenefitsEligibility(
                eligibility_id=str(uuid4()),
                program_name=result.get("program_name", program),
                program_type=program,
                is_eligible=result.get("is_eligible", False),
                confidence_score=float(result.get("confidence", 0.0)),
                eligibility_reason=result.get("reason", ""),
                estimated_savings_monthly=float(result.get("monthly_savings", 0.0)),
                application_url=result.get("application_url", ""),
                application_phone=result.get("application_phone", ""),
                screened_date=datetime.utcnow().isoformat()
            );
            here ++> elig;
            if result.get("is_eligible") {
                self.eligible_count += 1;
            }
        }

        report {"patient": here.name, "eligible_programs": self.eligible_count};
    }
}
