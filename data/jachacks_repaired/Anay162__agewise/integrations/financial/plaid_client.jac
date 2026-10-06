"""Plaid API client — financial account linking and transaction sync.

Plaid connects to the patient's bank accounts to:
1. Track medical bill payments
2. Detect suspicious charges (scam detection)
3. Identify recurring bills that may need monitoring
4. Monitor for missed payments and late fees

Uses plaid-python SDK. Install with: pip install plaid-python
"""

import from os { environ }

"""Build and return a configured Plaid API client."""
def _get_plaid_client() -> any {
    try {
        import from plaid { Environment }
        import from plaid.api { plaid_api }
        import from plaid.configuration { Configuration }
        import from plaid.api_client { ApiClient }

        env_name = environ.get("PLAID_ENV", "sandbox");
        env_map = {
            "sandbox": Environment.Sandbox,
            "development": Environment.Development,
            "production": Environment.Production
        };
        config = Configuration(
            host=env_map.get(env_name, Environment.Sandbox),
            api_key={
                "clientId": environ.get("PLAID_CLIENT_ID", ""),
                "secret": environ.get("PLAID_SECRET", "")
            }
        );
        return plaid_api.PlaidApi(ApiClient(config));
    } except ImportError {
        raise ImportError("plaid-python not installed. Run: pip install plaid-python");
    }
}

"""Create a Plaid Link token to initiate account connection."""
def create_link_token(user_id: str, client_name: str = "AgeWise") -> str {
    try {
        import from plaid.model.link_token_create_request { LinkTokenCreateRequest }
        import from plaid.model.link_token_create_request_user { LinkTokenCreateRequestUser }
        import from plaid.model.products { Products }
        import from plaid.model.country_code { CountryCode }
    } except ImportError {
        return "";
    }

    client = _get_plaid_client();
    request = LinkTokenCreateRequest(
        user=LinkTokenCreateRequestUser(client_user_id=user_id),
        client_name=client_name,
        products=[Products("transactions")],
        country_codes=[CountryCode("US")],
        language="en"
    );
    response = client.link_token_create(request);
    return response.link_token;
}

"""Sync transactions from Plaid using incremental cursor-based sync."""
def sync_transactions(access_token: str, cursor: str = "") -> dict {
    try {
        import from plaid.model.transactions_sync_request { TransactionsSyncRequest }
    } except ImportError {
        return {"added": [], "modified": [], "removed": [], "next_cursor": ""};
    }

    client = _get_plaid_client();
    has_more = True;
    added = [];
    modified = [];
    removed = [];
    current_cursor = cursor;

    while has_more {
        request = TransactionsSyncRequest(
            access_token=access_token,
            cursor=current_cursor if current_cursor else None
        );
        response = client.transactions_sync(request);
        added.extend(response.added);
        modified.extend(response.modified);
        removed.extend(response.removed);
        current_cursor = response.next_cursor;
        has_more = response.has_more;
    }

    return {
        "added": [_txn_to_dict(t) for t in added],
        "modified": [_txn_to_dict(t) for t in modified],
        "removed": [t.transaction_id for t in removed],
        "next_cursor": current_cursor
    };
}

"""Get all accounts linked to an access token."""
def get_accounts(access_token: str) -> list[dict] {
    try {
        import from plaid.model.accounts_get_request { AccountsGetRequest }
    } except ImportError {
        return [];
    }

    client = _get_plaid_client();
    request = AccountsGetRequest(access_token=access_token);
    response = client.accounts_get(request);
    return [
        {
            "account_id": acc.account_id,
            "name": acc.name,
            "official_name": acc.official_name or "",
            "type": str(acc.type),
            "subtype": str(acc.subtype) if acc.subtype else "",
            "mask": acc.mask or "",
            "balance_current": acc.balances.current,
            "balance_available": acc.balances.available
        }
        for acc in response.accounts
    ];
}

def _txn_to_dict(t: any) -> dict {
    return {
        "transaction_id": t.transaction_id,
        "account_id": t.account_id,
        "amount": float(t.amount),
        "merchant_name": t.merchant_name or t.name or "",
        "date": str(t.date),
        "category": t.category or [],
        "pending": t.pending,
        "payment_channel": str(t.payment_channel) if t.payment_channel else "other"
    };
}
