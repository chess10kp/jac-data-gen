"""Dispute Pipeline — full billing error detection and appeal generation.

Runs in sequence:
  1. FeeScheduleAuditor — check charges vs Medicare fee schedule
  2. NCCIPTPChecker — check NCCI bundling edits
  3. NCCIMUEChecker — check unit limits
  4. DuplicateClaimDetector — find duplicate charges
  5. DisputeCreator — create Dispute nodes with LLM-enriched citations
  6. AppealLetterGenerator — draft Level 1 appeal letters
  7. AppealTracker — monitor deadlines

Entry: spawn on Patient node.
"""

import from graph.nodes.patient { Patient }
import from graph.walkers.disputes.fee_schedule_auditor { FeeScheduleAuditor }
import from graph.walkers.disputes.ncci_ptp_checker { NCCIPTPChecker }
import from graph.walkers.disputes.ncci_mue_checker { NCCIMUEChecker }
import from graph.walkers.disputes.duplicate_claim_detector { DuplicateClaimDetector }
import from graph.walkers.disputes.dispute_creator { DisputeCreator }
import from graph.walkers.disputes.appeal_letter_generator { AppealLetterGenerator }
import from graph.walkers.disputes.appeal_tracker { AppealTracker }

walker DisputePipeline {
    has patient_state: str = "XX",
        auto_generate_appeals: bool = True;

    can run with Patient entry {
        print(f"[DisputePipeline] Starting audit for patient: {here.name}");

        # Fee schedule check
        here spawn FeeScheduleAuditor(patient_state=self.patient_state);

        # NCCI checks
        here spawn NCCIPTPChecker();
        here spawn NCCIMUEChecker();

        # Duplicate detection
        here spawn DuplicateClaimDetector();

        # Enrich disputes with LLM assessment
        here spawn DisputeCreator();

        # Generate appeal letters for open disputes
        if self.auto_generate_appeals {
            here spawn AppealLetterGenerator(
                patient_name=here.name,
                patient_medicare_id=here.medicare_id
            );
        }

        # Track deadlines
        here spawn AppealTracker();

        print(f"[DisputePipeline] Complete for patient: {here.name}");
    }
}
