"""MX Technologies client — alternative to Plaid for financial data aggregation."""

import from os { environ }

glob MX_BASE_URL: str = "https://int-api.mx.com";  # Atrium API
glob MX_PROD_URL: str = "https://api.mx.com";

"""Return the MX API base URL based on environment."""
def get_base_url() -> str {
    if environ.get("APP_ENV") == "production" {
        return MX_PROD_URL;
    }
    return MX_BASE_URL;
}

"""Build MX API authentication headers."""
def _get_headers() -> dict {
    import from base64 { b64encode }
    client_id = environ.get("MX_CLIENT_ID", "");
    api_key = environ.get("MX_API_KEY", "");
    credentials = b64encode(f"{client_id}:{api_key}".encode()).decode();
    return {
        "Authorization": f"Basic {credentials}",
        "Accept": "application/vnd.mx.api.v1+json",
        "Content-Type": "application/json"
    };
}

"""Create an MX user record."""
def create_user(user_id: str) -> dict {
    try {
        import from httpx { Client }
        with (Client() as any) as c {
            resp = c.post(
                f"{get_base_url()}/users",
                headers=_get_headers(),
                json={"user": {"id": user_id}}
            );
            resp.raise_for_status();
            return resp.json().get("user", {});
        }
    } except Exception as e {
        print(f"[MX] Create user failed: {e}");
        return {};
    }
}

"""Fetch all accounts for an MX user."""
def get_accounts(mx_user_guid: str) -> list[dict] {
    try {
        import from httpx { Client }
        with (Client() as any) as c {
            resp = c.get(
                f"{get_base_url()}/users/{mx_user_guid}/accounts",
                headers=_get_headers()
            );
            resp.raise_for_status();
            return resp.json().get("accounts", []);
        }
    } except Exception as e {
        print(f"[MX] Get accounts failed: {e}");
        return [];
    }
}

"""Fetch recent transactions for an MX account."""
def get_transactions(mx_user_guid: str, account_guid: str, days_back: int = 90) -> list[dict] {
    try {
        import from httpx { Client }
        import from datetime { datetime, timedelta }
        from_date = (datetime.utcnow() - timedelta(days=days_back)).strftime("%Y-%m-%d");
        with (Client() as any) as c {
            resp = c.get(
                f"{get_base_url()}/users/{mx_user_guid}/accounts/{account_guid}/transactions",
                headers=_get_headers(),
                params={"from_date": from_date, "records_per_page": 500}
            );
            resp.raise_for_status();
            return resp.json().get("transactions", []);
        }
    } except Exception as e {
        print(f"[MX] Get transactions failed: {e}");
        return [];
    }
}
