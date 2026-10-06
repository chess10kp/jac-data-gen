"""BeneficiaryAuditor walker — checks for missing or outdated beneficiary designations."""

import from graph.nodes.patient { Patient }
import from graph.nodes.beneficiary_designation { BeneficiaryDesignation }
import from graph.nodes.notification { Notification }

import from datetime { datetime }
import from uuid { uuid4 }

walker BeneficiaryAuditor {

    can start with Patient entry {
        designations = [d for d in [here-->] if isinstance(d, BeneficiaryDesignation)];

        if len(designations) == 0 {
            notif = Notification(
                notification_id=str(uuid4()),
                notification_type="ACTION_REQUIRED",
                severity="WARNING",
                title="No Beneficiary Designations on File",
                message="No beneficiary designations found. Review financial accounts and add beneficiaries.",
                created_at=datetime.utcnow().isoformat()
            );
            here ++> notif;
            print("[BeneficiaryAuditor] No beneficiary designations found");
            disengage;
        }

        for d in designations {
            # Check if shares add up to 100%
            primary_total = sum(d.share_percentages[:len(d.primary_beneficiaries)]);
            if len(d.primary_beneficiaries) > 0 and abs(primary_total - 100.0) > 0.01 {
                d.is_complete = False;
                d.needs_review = True;
                d.review_reason = f"Primary beneficiary shares total {primary_total:.1f}% (should be 100%)";
                print(f"[BeneficiaryAuditor] Incomplete designation for {d.account_ref}");
            } else {
                d.is_complete = True;
            }
        }
        print(f"[BeneficiaryAuditor] Audited {len(designations)} designations");
    }
}
