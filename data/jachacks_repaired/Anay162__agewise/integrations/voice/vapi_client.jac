"""Vapi.ai voice agent client — alternative to Bland.ai for voice calls."""

import from os { environ }

glob VAPI_BASE_URL: str = "https://api.vapi.ai";

"""
Initiate an outbound call via Vapi.ai.
Returns call object with call_id on success.
"""
def initiate_call(phone_number: str, assistant_id: str, call_data: dict = {}) -> dict {
    try {
        import from httpx { Client }
        api_key = environ.get("VAPI_API_KEY", "");
        if api_key == "" {
            print("[Vapi] Missing API key");
            return {"error": "Missing VAPI_API_KEY"};
        }
        payload: dict[str, any] = {
            "phoneNumberId": environ.get("VAPI_PHONE_NUMBER_ID", ""),
            "assistantId": assistant_id,
            "customer": {"number": phone_number}
        };
        if call_data {
            payload["assistantOverrides"] = {"variableValues": call_data};
        }
        with (Client() as any) as c {
            resp = c.post(
                f"{VAPI_BASE_URL}/call",
                headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
                json=payload
            );
            resp.raise_for_status();
            return resp.json();
        }
    } except Exception as e {
        print(f"[Vapi] Call initiation failed: {e}");
        return {"error": str(e)};
    }
}

"""Fetch the current status and details of a Vapi call."""
def get_call_status(call_id: str) -> dict {
    try {
        import from httpx { Client }
        api_key = environ.get("VAPI_API_KEY", "");
        with (Client() as any) as c {
            resp = c.get(
                f"{VAPI_BASE_URL}/call/{call_id}",
                headers={"Authorization": f"Bearer {api_key}"}
            );
            resp.raise_for_status();
            return resp.json();
        }
    } except Exception as e {
        print(f"[Vapi] Get call status failed: {e}");
        return {"error": str(e)};
    }
}

"""List all configured Vapi assistants."""
def list_assistants() -> list[dict] {
    try {
        import from httpx { Client }
        api_key = environ.get("VAPI_API_KEY", "");
        with (Client() as any) as c {
            resp = c.get(
                f"{VAPI_BASE_URL}/assistant",
                headers={"Authorization": f"Bearer {api_key}"}
            );
            resp.raise_for_status();
            return resp.json();
        }
    } except Exception as e {
        print(f"[Vapi] List assistants failed: {e}");
        return [];
    }
}
