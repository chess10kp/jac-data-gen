"""Bland.ai API client — voice agent integration for outbound calls.

Bland.ai is used to make automated phone calls to insurers, providers,
pharmacies, and government agencies on behalf of the patient.

API docs: https://docs.bland.ai
"""

import from os { environ }
import from httpx { Client }

glob BLAND_BASE_URL = "https://api.bland.ai";

def get_bland_client() -> Client {
    api_key = environ.get("BLAND_API_KEY", "");
    if api_key == "" {
        raise ValueError("BLAND_API_KEY environment variable not set");
    }
    return Client(
        base_url=BLAND_BASE_URL,
        headers={"authorization": api_key, "Content-Type": "application/json"},
        timeout=30.0
    );
}

def initiate_call(
    phone_number: str,
    call_script: dict,
    metadata: dict = {},
    voice: str = "nat",
    max_duration: int = 600
) -> dict {
    """Initiate an outbound call via Bland.ai.
    Returns call object with: call_id, status, created_at
""";
client = get_bland_client();
payload = {
    "phone_number": phone_number,
    "task": call_script.get("main_ask", ""),
    "model": "enhanced",
    "language": "en-US",
    "voice": voice,
    "max_duration": max_duration,
    "answered_by_enabled": True,
    "wait_for_greeting": True,
    "record": True,
    "amd": False,
    "request_data": metadata,
    "analysis_schema": {
        "call_successful": "boolean",
        "resolution_offered": "string",
        "reference_number": "string",
        "commitments_made": "string",
        "next_steps": "string"
    },
    "metadata": metadata,
    "summary_prompt": (
        "Summarize: what was requested, what the representative said, "
        "any commitments made, reference numbers, and next steps."
    )
};

response = client.post("/v1/calls", json=payload);
response.raise_for_status();
return response.json();
}

"""Get the current status of a call."""
def get_call_status(call_id: str) -> dict {
    client = get_bland_client();
    response = client.get(f"/v1/calls/{call_id}");
    response.raise_for_status();
    return response.json();
}

"""Get the full transcript of a completed call."""
def get_call_transcript(call_id: str) -> str {
    status = get_call_status(call_id);
    transcript_raw = status.get("transcripts", []);
    lines = [];
    for item in transcript_raw {
        speaker = "Agent" if item.get("user") == "assistant" else "Rep";
        text = item.get("text", "");
        if text {
            lines.append(f"{speaker}: {text}");
        }
    }
    return "\n".join(lines);
}

"""Get the recording URL for a completed call."""
def get_call_recording_url(call_id: str) -> str {
    status = get_call_status(call_id);
    return status.get("recording_url", "");
}

def initiate_bland_call(
    phone_number: str,
    task: str,
    call_data: dict = {}
) -> dict {
    """Simplified wrapper around initiate_call for the voice walkers.
    Returns dict with call_id and status.
    """;
    script = {"main_ask": task};
    return initiate_call(
        phone_number=phone_number,
        call_script=script,
        metadata=call_data
    );
}
