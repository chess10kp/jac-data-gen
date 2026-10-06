"""Blue Button 2.0 API client — fetches Medicare claims data for a beneficiary."""

import from os { environ }

glob BB_BASE_URL: str = "https://api.bluebutton.cms.gov/v2";
glob BB_SANDBOX_URL: str = "https://sandbox.bluebutton.cms.gov/v2";

"""Return the appropriate Blue Button base URL based on environment."""
def get_base_url() -> str {
    if environ.get("APP_ENV") == "production" {
        return BB_BASE_URL;
    }
    return BB_SANDBOX_URL;
}

"""Return the OAuth2 authorization URL."""
def get_auth_url() -> str {
    client_id = environ.get("BLUE_BUTTON_CLIENT_ID", "");
    base = get_base_url();
    return f"{base}/o/authorize/?client_id={client_id}&response_type=code&scope=patient/Patient.read patient/Coverage.read patient/ExplanationOfBenefit.read";
}

"""
Exchange OAuth2 authorization code for access token.
Returns token response dict or empty dict on failure.
"""
def exchange_code_for_token(auth_code: str) -> dict {
    try {
        import from httpx { Client }
        client_id = environ.get("BLUE_BUTTON_CLIENT_ID", "");
        client_secret = environ.get("BLUE_BUTTON_CLIENT_SECRET", "");
        base = get_base_url();
        with (Client() as any) as c {
            resp = c.post(
                f"{base}/o/token/",
                data={
                    "grant_type": "authorization_code",
                    "code": auth_code,
                    "client_id": client_id,
                    "client_secret": client_secret
                }
            );
            resp.raise_for_status();
            return resp.json();
        }
    } except Exception as e {
        print(f"[BlueButton] Token exchange failed: {e}");
        return {};
    }
}

"""
Fetch Explanation of Benefits resources for a beneficiary.
Returns list of FHIR ExplanationOfBenefit resources.
"""
def fetch_eobs(access_token: str, patient_id: str = "") -> list[dict] {
    try {
        import from httpx { Client }
        base = get_base_url();
        headers = {"Authorization": f"Bearer {access_token}"};
        url = f"{base}/fhir/R4/ExplanationOfBenefit/";
        if patient_id != "" {
            url += f"?patient={patient_id}";
        }
        results = [];
        with (Client() as any) as c {
            cc: any = c;
            while url != "" {
                resp: any = cc.get(url, headers=headers);
                resp.raise_for_status();
                bundle = resp.json();
                for `entry in bundle.get("entry", []) {
                    results.append(`entry.get("resource", {}));
                }
                next_url = "";
                for link in bundle.get("link", []) {
                    if link.get("relation") == "next" {
                        next_url = link.get("url", "");
                    }
                }
                url = next_url;
            }
        }
        print(f"[BlueButton] Fetched {len(results)} EOBs");
        return results;
    } except Exception as e {
        print(f"[BlueButton] EOB fetch failed: {e}");
        return [];
    }
}

"""Fetch Coverage (insurance plan) resources for a beneficiary."""
def fetch_coverage(access_token: str) -> list[dict] {
    try {
        import from httpx { Client }
        base = get_base_url();
        headers = {"Authorization": f"Bearer {access_token}"};
        with (Client() as any) as c {
            resp = c.get(f"{base}/fhir/R4/Coverage/", headers=headers);
            resp.raise_for_status();
            bundle = resp.json();
            return [e.get("resource", {}) for e in bundle.get("entry", [])];
        }
    } except Exception as e {
        print(f"[BlueButton] Coverage fetch failed: {e}");
        return [];
    }
}
