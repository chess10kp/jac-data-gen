"""Document Pipeline — full document intake flow.

Runs in sequence:
  1. DocumentIngest — pull new emails/uploads → create Document nodes
  2. DocumentClassify — classify each doc via by llm()
  3. EOBParser — parse MSN/EOB docs into structured nodes
  4. DocumentExtract — extract claims and legal docs
  5. ClaimBuilder — finalize claim structure with line items
  6. BillReconciler — compare bills vs EOBs, flag discrepancies
  7. PlainEnglishTranslator — generate patient-friendly summaries

Entry: spawn on Patient node.
"""

import from graph.nodes.patient { Patient }
import from graph.walkers.intake.document_ingest { DocumentIngest }
import from graph.walkers.intake.document_classify { DocumentClassify }
import from graph.walkers.intake.eob_parser { EOBParser }
import from graph.walkers.intake.document_extract { DocumentExtract }
import from graph.walkers.intake.claim_builder { ClaimBuilder }
import from graph.walkers.intake.bill_reconciler { BillReconciler }
import from graph.walkers.intake.plain_english_translator { PlainEnglishTranslator }

walker DocumentPipeline {
    has source: str = "email",
        raw_content: str = "",
        original_filename: str = "",
        dry_run: bool = False;

    can run with Patient entry {
        print(f"[DocumentPipeline] Starting for patient: {here.name}");

        # Step 1: Ingest
        here spawn DocumentIngest(
            source=self.source,
            raw_content=self.raw_content,
            original_filename=self.original_filename
        );

        # Step 2: Classify
        here spawn DocumentClassify();

        # Step 3: Parse EOBs
        here spawn EOBParser();

        # Step 4: Extract claims and legal docs
        here spawn DocumentExtract();

        # Step 5: Build claim structure
        here spawn ClaimBuilder();

        # Step 6: Reconcile bills vs EOBs
        here spawn BillReconciler();

        # Step 7: Generate plain-English summaries
        here spawn PlainEnglishTranslator();

        print(f"[DocumentPipeline] Complete for patient: {here.name}");
    }
}
