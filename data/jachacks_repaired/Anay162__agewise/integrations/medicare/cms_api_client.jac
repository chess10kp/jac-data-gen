"""CMS data.cms.gov API client for public reference data."""

import from os { environ }

glob CMS_DATA_API: str = "https://data.cms.gov/api/1";
glob CMS_FHIR_API: str = "https://api.cms.gov/fhir";

"""Look up a provider by NPI from the NPPES registry."""
def fetch_npi_registry(npi: str) -> dict {
    try {
        import from httpx { Client }
        with (Client() as any) as c {
            resp = c.get(
                "https://npiregistry.cms.hhs.gov/api/",
                params={"number": npi, "version": "2.1"}
            );
            resp.raise_for_status();
            data = resp.json();
            results = data.get("results", []);
            if len(results) > 0 {
                return results[0];
            }
            return {};
        }
    } except Exception as e {
        print(f"[CMS_API] NPI lookup failed for {npi}: {e}");
        return {};
    }
}

"""Check Medicare provider enrollment status via PECOS API."""
def fetch_provider_enrollment(npi: str) -> dict {
    try {
        import from httpx { Client }
        with (Client() as any) as c {
            resp = c.get(
                f"{CMS_DATA_API}/providers/{npi}/enrollment",
                headers={"Accept": "application/json"}
            );
            if resp.status_code == 200 {
                return resp.json();
            }
            return {"enrolled": False, "npi": npi};
        }
    } except Exception as e {
        print(f"[CMS_API] Enrollment lookup failed for {npi}: {e}");
        return {"enrolled": False, "npi": npi};
    }
}

"""Return MAC contractor info for a given state (for appeal addresses)."""
def fetch_mac_contractor_info(state: str) -> dict {
    # Static mapping — update as CMS reassigns contracts
    mac_map = {
        "AL": {"name": "Cahaba GBA", "jurisdiction": "J10"},
        "AK": {"name": "Noridian Healthcare Solutions", "jurisdiction": "J2"},
        "AZ": {"name": "Noridian Healthcare Solutions", "jurisdiction": "J3"},
        "CA": {"name": "Noridian Healthcare Solutions", "jurisdiction": "J1"},
        "FL": {"name": "First Coast Service Options", "jurisdiction": "J9"},
        "GA": {"name": "Palmetto GBA", "jurisdiction": "J11"},
        "IL": {"name": "WPS Government Health Administrators", "jurisdiction": "J6"},
        "NY": {"name": "National Government Services", "jurisdiction": "J13"},
        "TX": {"name": "Novitas Solutions", "jurisdiction": "J4"},
        "WA": {"name": "Noridian Healthcare Solutions", "jurisdiction": "J2"}
    };
    return mac_map.get(state, {"name": "Contact 1-800-MEDICARE", "jurisdiction": "Unknown"});
}
