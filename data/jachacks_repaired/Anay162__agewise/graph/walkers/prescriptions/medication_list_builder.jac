import from graph.nodes.patient { Patient }
import from graph.nodes.prescription { Prescription }
import from graph.nodes.medication { Medication }

import from datetime { datetime }
import from uuid { uuid4 }


def _compute_next_fill(last_filled: str, days_supply: int) -> list {
    if not last_filled {
        return ["", -1];
    }
    try {
        filled_dt: datetime = datetime.strptime(last_filled, "%Y-%m-%d");
        now_dt: datetime = datetime.utcnow();
        delta = now_dt - filled_dt;
        days_since: int = delta.days;
        days_until: int = days_supply - days_since;
        next_fill_str: str = str(filled_dt)[:10];
        return [next_fill_str, days_until];
    } except Exception {
        return ["", 0];
    }
}


walker MedicationListBuilder {
    has built: int = 0,
        updated: int = 0;

    can start with Patient entry {
        prescriptions = [n for n in [here-->] if isinstance(n, Prescription) and n.status == "ACTIVE"];

        existing_meds: dict = {};
        for n in [here-->] {
            if isinstance(n, Medication) {
                existing_meds[n.generic_name.lower()] = n;
            }
        }

        for rx in prescriptions {
            key = (rx.generic_name or rx.drug_name).lower().strip();
            if not key {
                continue;
            }

            fill_result = _compute_next_fill(str(rx.fill_date), int(rx.days_supply));
            next_fill_date: str = str(fill_result[0]);
            days_until: int = int(fill_result[1]);

            if key in existing_meds {
                med = existing_meds[key];
                med.last_filled = str(rx.fill_date) or med.last_filled;
                med.days_supply = int(rx.days_supply);
                med.refills_remaining = int(rx.refills_remaining);
                med.next_fill_due = next_fill_date;
                med.days_until_refill = days_until;
                med.prescribing_provider = str(rx.prescriber_name) or med.prescribing_provider;
                med.pharmacy_name = str(rx.pharmacy_name) or med.pharmacy_name;
                self.updated += 1;
            } else {
                med = Medication(
                    medication_id=str(uuid4()),
                    drug_name=str(rx.drug_name),
                    generic_name=str(rx.generic_name or rx.drug_name),
                    ndc=str(rx.ndc_code),
                    strength=str(rx.dosage),
                    form="",
                    therapeutic_class="",
                    active_ingredient=str(rx.generic_name or rx.drug_name),
                    prescribing_provider=str(rx.prescriber_name),
                    pharmacy_name=str(rx.pharmacy_name),
                    last_filled=str(rx.fill_date),
                    days_supply=int(rx.days_supply),
                    refills_remaining=int(rx.refills_remaining),
                    next_fill_due=next_fill_date,
                    days_until_refill=days_until,
                    known_interactions=[],
                    active=True,
                    created_at=str(datetime.utcnow())
                );
                here ++> med;
                existing_meds[key] = med;
                self.built += 1;
                print(f"[MedicationListBuilder] Added: {med.drug_name} ({med.generic_name})");
            }
        }

        report {"patient": here.name, "built": self.built, "updated": self.updated};
    }
}
