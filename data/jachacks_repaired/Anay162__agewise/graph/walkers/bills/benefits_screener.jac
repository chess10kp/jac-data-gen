"""BenefitsScreener walker — screens patients for eligible assistance programs."""

import from graph.nodes.patient { Patient }
import from graph.nodes.benefits_eligibility { BenefitsEligibility }
import from abilities.llm_abilities { screen_benefits_eligibility }
import from datetime { datetime }
import from uuid { uuid4 }

glob PROGRAMS_TO_SCREEN: list[str] = [
    "EXTRA_HELP",
    "QMB",
    "SLMB",
    "SNAP",
    "LIHEAP",
    "MEDICARE_SAVINGS_PROGRAM",
    "STATE_PHARMACEUTICAL_ASSISTANCE"
];

walker BenefitsScreener {
    has patient_income: float = 0.0,
        patient_assets: float = 0.0,
        new_eligibilities: int = 0;

    can start with Patient entry {
        # Gather income/asset context from patient if available
        self.patient_income = getattr(here, "estimated_monthly_income", 0.0);
        self.patient_assets = getattr(here, "estimated_assets", 0.0);
        patient_state = here.state;
        patient_name = here.name;
        has_medicare = here.medicare_id != "";
        has_medicaid = here.medicaid_id != "";

        # Get already-screened programs
        already_screened = [n.program_type for n in [here-->] if isinstance(n, BenefitsEligibility)];

        for program in PROGRAMS_TO_SCREEN {
            if program in already_screened {
                continue;
            }

            result = screen_benefits_eligibility(
                program=program,
                state=patient_state,
                estimated_monthly_income=self.patient_income,
                estimated_assets=self.patient_assets,
                has_medicare=has_medicare,
                has_medicaid=has_medicaid,
                age=0
            );

            eligibility = BenefitsEligibility(
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
            here ++> eligibility;
            self.new_eligibilities += 1;

            if result.get("is_eligible", False) {
                savings = float(result.get("monthly_savings", 0.0));
                print(f"[BenefitsScreener] ELIGIBLE: {program} for {patient_name} — est. ${savings:.2f}/mo");
            }
        }

        report {"patient": patient_name, "new_screenings": self.new_eligibilities};
    }
}
