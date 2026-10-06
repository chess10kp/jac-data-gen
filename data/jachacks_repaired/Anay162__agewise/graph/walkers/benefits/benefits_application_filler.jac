"""BenefitsApplicationFiller walker — pre-fills benefit application forms."""

import from graph.nodes.patient { Patient }
import from graph.nodes.benefits_eligibility { BenefitsEligibility }
import from graph.nodes.document { Document }
import from abilities.llm_abilities { prefill_benefit_application }
import from datetime { datetime }
import from uuid { uuid4 }

walker BenefitsApplicationFiller {
    has programs_to_fill: list = [],
        forms_generated: int = 0;

    can fill with Patient entry {
        eligible = [
            n for n in [here-->]
            if isinstance(n, BenefitsEligibility)
            and n.is_eligible
            and (not self.programs_to_fill or n.program_type in self.programs_to_fill)
        ];

        for elig in eligible {
            result = prefill_benefit_application(
                program=elig.program_type,
                patient_name=here.name,
                patient_dob=here.dob,
                patient_address=here.address,
                patient_state=here.state,
                medicare_id=here.medicare_id
            );
            if result.get("form_content") {
                doc = Document(
                    doc_id=str(uuid4()),
                    doc_type="BENEFIT_APPLICATION",
                    title=f"Pre-filled {elig.program_name} Application",
                    raw_text=result.get("form_content", ""),
                    classification="BENEFIT_APPLICATION",
                    source="GENERATED",
                    ingested_at=datetime.utcnow().isoformat(),
                    processed=False
                );
                here ++> doc;
                self.forms_generated += 1;
            }
        }

        report {"patient": here.name, "forms_generated": self.forms_generated};
    }
}
