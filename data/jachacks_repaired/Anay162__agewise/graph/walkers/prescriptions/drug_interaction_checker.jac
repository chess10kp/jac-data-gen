import from graph.nodes.patient { Patient }
import from graph.nodes.medication { Medication }
import from graph.nodes.notification { Notification }
import from abilities.llm_abilities { check_drug_interactions }

import from datetime { datetime }
import from uuid { uuid4 }

glob SEVERITY_TO_NOTIFICATION_LEVEL: dict = {
    "CONTRAINDICATED": "CRITICAL",
    "SERIOUS": "HIGH",
    "MODERATE": "MEDIUM",
    "MINOR": "LOW"
};
walker DrugInteractionChecker {
    has interactions_found: int = 0;

    can start with Patient entry {
        medications = [n for n in [here-->] if isinstance(n, Medication) and n.active];

        if len(medications) < 2 {
            report {"patient": here.name, "interactions_found": 0, "message": "Fewer than 2 active medications"};
            disengage;
        }

        med_names = [f"{m.drug_name} ({m.generic_name}) {m.strength}".strip("() ") for m in medications];

        interactions = check_drug_interactions(medication_names=med_names);

        if not interactions {
            print(f"[DrugInteractionChecker] No interactions found for {here.name}");
            report {"patient": here.name, "interactions_found": 0};
            disengage;
        }

        for interaction in interactions {
            drug_a: str = str(interaction.get("drug_a", ""));
            drug_b: str = str(interaction.get("drug_b", ""));
            severity: str = str(interaction.get("severity", "MODERATE"));
            mechanism: str = str(interaction.get("mechanism", ""));
            clinical_effect: str = str(interaction.get("clinical_effect", ""));
            recommendation: str = str(interaction.get("recommendation", "Contact prescriber."));

            notif_level = SEVERITY_TO_NOTIFICATION_LEVEL.get(severity, "MEDIUM");
            title = f"Drug Interaction ({severity}): {drug_a} + {drug_b}";
            message = (
                f"Potential {severity.lower()} interaction between {drug_a} and {drug_b}. "
                f"{clinical_effect} {recommendation}"
            );
            if mechanism {
                message += f" Mechanism: {mechanism}";
            }

            notif = Notification(
                notification_id=str(uuid4()),
                notification_type="DRUG_INTERACTION",
                severity=notif_level,
                title=title,
                message=message,
                created_at=str(datetime.utcnow()),
                delivered_at="",
                read_at=""
            );
            here ++> notif;
            self.interactions_found += 1;
            print(f"[DrugInteractionChecker] {severity} interaction: {drug_a} + {drug_b}");
        }

        report {"patient": here.name, "interactions_found": self.interactions_found};
    }
}
