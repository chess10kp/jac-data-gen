"""PharmacyBenefitChecker walker — checks prescriptions against Part D formulary."""

import from graph.nodes.patient { Patient }
import from graph.nodes.prescription { Prescription }
import from abilities.llm_abilities { check_formulary_coverage }
import from abilities.notification_sender { send_notification }

walker PharmacyBenefitChecker {
    has issues_found: int = 0;

    can check with Patient entry {
        for med in [here-->] {
            for rx in [med-->] {
                if not isinstance(rx, Prescription) or not rx.is_active {
                    continue;
                }
                result = check_formulary_coverage(
                    drug_name=rx.drug_name,
                    ndc=rx.ndc,
                    plan_type="PART_D"
                );
                if result.get("tier_changed") or result.get("not_covered") {
                    self.issues_found += 1;
                    send_notification(
                        patient_id=here.name,
                        channel="EMAIL",
                        message=f"Formulary alert for {rx.drug_name}: {result.get('message', '')}",
                        severity="MEDIUM"
                    );
            }
        }
        }
        report {"patient": here.name, "formulary_issues": self.issues_found};
    }
}
