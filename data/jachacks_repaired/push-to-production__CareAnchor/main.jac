"""Care Anchor entry point."""

import from dotenv { load_dotenv }
import from os { getenv }

glob _: bool = load_dotenv() or True;

import from agents.auth { register_or_login, get_user_by_token, logout }
import from agents.orchestrator {
    create_session,
    process_message,
    get_session,
    export_json,
    export_pdf,
    load_demo,
    list_sessions,
    load_session
}

import from .components.AppShell { AppShell }

def:pub app() -> JsxElement {
    return <AppShell />;
}
