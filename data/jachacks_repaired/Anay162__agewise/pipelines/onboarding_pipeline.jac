"""Onboarding Pipeline — sets up a new patient's graph from scratch.

Runs when a new patient is added:
1. Links Plaid financial accounts
2. Pulls existing Medicare claims from Blue Button 2.0 (if available)
3. Scans any uploaded documents to build baseline graph
4. Runs initial dispute detection
5. Generates first digest

Entry: spawn on Patient node with Plaid access token provided.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.financial_account { FinancialAccount }
import from integrations.financial.plaid_client { get_accounts }
import from integrations.financial.transaction_monitor { TransactionMonitor }
import from pipelines.document_pipeline { DocumentPipeline }
import from pipelines.dispute_pipeline { DisputePipeline }
import from pipelines.weekly_digest_pipeline { WeeklyDigestPipeline }

import from datetime { datetime }
import from uuid { uuid4 }

walker OnboardingPipeline {
    has plaid_access_token: str = "",
        patient_state: str = "XX",
        initial_documents: list[dict] = [];

    can run with Patient entry {
        print("[OnboardingPipeline] Starting onboarding");

        # Step 1: Link Plaid accounts
        if self.plaid_access_token != "" {
            try {
                accounts: list[dict] = get_accounts(self.plaid_access_token);
                for acc_data in accounts {
                    acct = FinancialAccount(
                        plaid_item_id=self.plaid_access_token[:20],
                        plaid_account_id=acc_data.get("account_id", str(uuid4())),
                        institution_name=acc_data.get("name", ""),
                        account_type=acc_data.get("type", ""),
                        account_subtype=acc_data.get("subtype", ""),
                        mask=acc_data.get("mask", ""),
                        official_name=acc_data.get("official_name", ""),
                        balance_current=float(acc_data.get("balance_current", 0) or 0),
                        link_date=str(datetime.utcnow())
                    );
                    here ++> acct;
                }
                print(f"[OnboardingPipeline] Linked {len(accounts)} financial accounts");

                # Sync initial transactions
                here spawn TransactionMonitor(
                    access_tokens={acc["account_id"]: self.plaid_access_token for acc in accounts}
                );
            } except Exception as e {
                print(f"[OnboardingPipeline] Plaid error: {e}");
            }
        }

        # Step 2: Process any uploaded documents
        for doc in self.initial_documents {
            here spawn DocumentPipeline(
                source="upload",
                raw_content=doc.get("content", ""),
                original_filename=doc.get("filename", "upload")
            );
        }

        # Step 3: Run dispute detection
        here spawn DisputePipeline(patient_state=self.patient_state, auto_generate_appeals=False);

        # Step 4: Generate first digest
        here spawn WeeklyDigestPipeline();

        print("[OnboardingPipeline] Onboarding complete");
    }
}
