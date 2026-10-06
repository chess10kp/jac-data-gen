"""TransactionMonitor — syncs Plaid transactions into the graph.

Walks FinancialAccount nodes, calls Plaid API to get new transactions,
creates Transaction nodes, and flags medical charges and suspicious activity.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.financial_account { FinancialAccount }
import from graph.nodes.transaction { Transaction }
import from integrations.financial.plaid_client { sync_transactions }

import from datetime { datetime }
import from uuid { uuid4 }

# Medical-related Plaid category identifiers
glob MEDICAL_CATEGORIES = [
    "Medical", "Pharmacy", "Hospitals", "Doctor", "Dentist",
    "Healthcare", "Medicare", "Insurance"
];

walker TransactionMonitor {
    has access_tokens: dict = {};   # plaid_account_id → access_token mapping
    has cursors: dict = {};         # plaid_account_id → sync cursor

    can start with Patient entry {
        visit [-->];
    }

    can sync_account with FinancialAccount entry {
        account_id = here.plaid_account_id;
        access_token = self.access_tokens.get(account_id, "");

        if access_token == "" {
            print(f"[TransactionMonitor] No access token for account {account_id}");
            disengage;
        }

        cursor = self.cursors.get(account_id, "");

        try {
            result = sync_transactions(access_token=access_token, cursor=cursor);
            added = result.get("added", []);
            self.cursors[account_id] = result.get("next_cursor", "");

            new_count = 0;
            for t_data in added {
                # Avoid duplicates
                txn_id = t_data.get("transaction_id", "");
                existing = [__n for __n in [t for t in [here-->] if isinstance(__n, Transaction)] if t.plaid_transaction_id == txn_id];
                if len(existing) > 0 {
                    continue;
                }

                # Determine if medical
                cats = t_data.get("category", []);
                is_medical = any(
                    mc.lower() in cat.lower()
                    for mc in MEDICAL_CATEGORIES
                    for cat in cats
                );

                txn = Transaction(
                    plaid_transaction_id=txn_id,
                    amount=float(t_data.get("amount", 0)),
                    merchant_name=t_data.get("merchant_name", ""),
                    date=str(t_data.get("date", "")),
                    category=cats,
                    payment_channel=t_data.get("payment_channel", "other"),
                    is_pending=bool(t_data.get("pending", False)),
                    is_medical=is_medical,
                    created_at=datetime.utcnow().isoformat()
                );
                here ++> txn;
                new_count += 1;
            }

            here.last_synced = datetime.utcnow().isoformat();
            print(f"[TransactionMonitor] Synced {new_count} new transactions for account {account_id[:8]}...");

        } except Exception as e {
            print(f"[TransactionMonitor] Error syncing account {account_id}: {e}");
        }
    }
}
