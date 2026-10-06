"""Legal review pipeline — scans all legal documents for issues and upcoming expirations."""

import from graph.nodes.patient { Patient }
import from graph.walkers.legal.legal_doc_scanner { LegalDocScanner }
import from graph.walkers.legal.expiry_monitor { ExpiryMonitor }
import from graph.walkers.legal.beneficiary_auditor { BeneficiaryAuditor }
import from graph.walkers.legal.deadline_tracker { DeadlineTracker }

walker LegalReviewPipeline {

    can run with Patient entry {
        print(f"[LegalReviewPipeline] Starting legal review for patient: {here.name}");

        # Step 1: Scan for missing/outdated documents
        here spawn LegalDocScanner();

        # Step 2: Check for expiring documents
        here spawn ExpiryMonitor();

        # Step 3: Audit beneficiary designations
        here spawn BeneficiaryAuditor();

        # Step 4: Check all deadlines
        here spawn DeadlineTracker();

        print(f"[LegalReviewPipeline] Legal review complete for: {here.name}");
        report {"patient": here.name, "status": "legal_review_complete"};
    }
}

with entry {
    print("LegalReviewPipeline module loaded.");
}
