"""PrescriptionPipeline — full prescription flow: build med list → check interactions → track refills → prior auth followup."""

import from graph.nodes.patient { Patient }
import from graph.walkers.prescriptions.medication_list_builder { MedicationListBuilder }
import from graph.walkers.prescriptions.refill_tracker { RefillTracker }
import from graph.walkers.prescriptions.drug_interaction_checker { DrugInteractionChecker }
import from graph.walkers.prescriptions.prior_auth_followup { PriorAuthFollowup }
import from graph.walkers.prescriptions.pharmacy_benefit_checker { PharmacyBenefitChecker }

walker PrescriptionPipeline {
    can run with Patient entry {
        here spawn MedicationListBuilder();
        here spawn RefillTracker();
        here spawn DrugInteractionChecker();
        here spawn PriorAuthFollowup();
        here spawn PharmacyBenefitChecker();
        report {"pipeline": "prescription", "patient": here.name, "status": "complete"};
    }
}
