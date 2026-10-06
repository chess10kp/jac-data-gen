"""Backboard.io memory client — persistent memory & RAG for walker context."""

import from os { getenv }
import from dotenv { load_dotenv }
import from json { loads }
import from requests { post, get }

glob _bb_env: any = load_dotenv();
glob _bb_key: str = getenv("BACKBOARD_API_KEY") or "";
glob _bb_base: str = "https://app.backboard.io/api";
glob _bb_assistant_id: str = "";
glob _bb_thread_id: str = "";

def _bb_setup() -> None {
    if _bb_assistant_id {
        return;
    }
    if not _bb_key {
        print("BACKBOARD_API_KEY not set — memory features disabled");
        return;
    }
    headers = {"X-API-Key": _bb_key};

    # Create assistant for memory operations
    resp = post(
        _bb_base + "/assistants",
        json={
            "name": "PropOS Memory",
            "system_prompt": "You are a property management memory system. Store and recall facts about tenants, units, vendors, and maintenance history."
        },
        headers=headers
    );
    resp.raise_for_status();
    _bb_assistant_id = str(resp.json()["assistant_id"]);

    # Create thread for memory context
    resp = post(
        _bb_base + "/assistants/" + _bb_assistant_id + "/threads",
        json={},
        headers=headers
    );
    resp.raise_for_status();
    _bb_thread_id = str(resp.json()["thread_id"]);
    print("Backboard memory ready: assistant=" + _bb_assistant_id);
}

def:pub bb_remember(fact: str) -> None {
    _bb_setup();
    if not _bb_assistant_id {
        return;
    }
    headers = {"X-API-Key": _bb_key};
    post(
        _bb_base + "/threads/" + _bb_thread_id + "/messages",
        headers=headers,
        json={
            "content": "Remember this fact: " + fact,
            "llm_provider": "openai",
            "model_name": "gpt-4o-mini",
            "stream": False,
            "memory": "Auto",
            "send_to_llm": "false"
        }
    );
}

def:pub bb_recall(query: str) -> str {
    _bb_setup();
    if not _bb_assistant_id {
        return "";
    }
    headers = {"X-API-Key": _bb_key};
    resp = post(
        _bb_base + "/threads/" + _bb_thread_id + "/messages",
        headers=headers,
        json={
            "content": "What do you remember about: " + query,
            "llm_provider": "openai",
            "model_name": "gpt-4o-mini",
            "stream": False,
            "memory": "Auto"
        }
    );
    resp.raise_for_status();
    return str(resp.json().get("content") or "");
}
