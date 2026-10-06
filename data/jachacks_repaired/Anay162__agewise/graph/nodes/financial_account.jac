"""FinancialAccount node — a linked bank/investment account via Plaid.

Plaid item_id is the persistent identifier. Transactions hang off
this node via has_transaction edges.
"""

node FinancialAccount {
    has plaid_item_id: str = "",
        plaid_account_id: str = "",
        institution_name: str = "",
        institution_id: str = "",
        account_type: str = "",         # checking | savings | credit | investment
        account_subtype: str = "",
        mask: str = "",                 # last 4 digits
        official_name: str = "",
        balance_current: float = 0.0,
        balance_available: float = 0.0,
        currency: str = "USD",
        last_synced: str = "",
        is_active: bool = True,
        link_date: str = "";
}
