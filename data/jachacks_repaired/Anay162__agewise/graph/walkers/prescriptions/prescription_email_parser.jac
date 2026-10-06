"""PrescriptionEmailParser walker — detects pharmacy notifications in emails."""

import from graph.nodes.patient { Patient }
import from graph.nodes.document { Document }
import from abilities.llm_abilities { extract_pharmacy_notification }

walker PrescriptionEmailParser {
    has notifications_processed: int = 0;

    can parse with Patient entry {
        docs = [
            n for n in [here-->]
            if isinstance(n, Document)
            and n.classification in ["PHARMACY_NOTIFICATION", "REFILL_REMINDER"]
            and not n.processed
        ];
        for doc in docs {
            result = extract_pharmacy_notification(email_text=doc.raw_text);
            if result.get("drug_name") {
                # Update matching prescription if found
                drug = result.get("drug_name", "");
                action = result.get("action", "");  # READY_FOR_PICKUP | REFILL_REMINDER | SHIPPED
                print(f"[PrescriptionEmailParser] {drug}: {action}");
                doc.processed = True;
                self.notifications_processed += 1;
            }
        }
        report {"notifications_processed": self.notifications_processed};
    }
}
