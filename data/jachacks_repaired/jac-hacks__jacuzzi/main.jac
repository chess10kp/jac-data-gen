"""Local phone pairing dashboard for Jacuzzi."""

import from uuid { uuid4 }
import from datetime { datetime, timezone }
import from claw_runtime {
    delete_workspace,
    ensure_openclaw_gateway,
    get_messages,
    inspect_openclaw_gateway,
    preferred_phone_access_origin,
    provider_config,
    provision_phone_user_workspace,
    provision_workspace,
    start_openclaw_gateway,
    stop_openclaw_gateway,
    talk_with_provider,
}

import "./styles.css";
import from "./lib/pair-url.ts" {
    buildPairUrl,
    clearStoredPairOrigin,
    getSavedPairOrigin,
    getSuggestedPairOrigin,
    isCurrentOriginLocalOnly,
    isLocalOnlyOrigin,
    storePairOrigin,
}
import from "./lib/qr.ts" { renderQrSvg }
import from "./lib/clipboard.ts" { copyText }
import from "./lib/device.ts" { getClientProfile }
import from "./lib/jac-session.ts" { prepareJacClientSession }
import from "./lib/session-watch.ts" { getActiveDashboardSessionToken, watchDashboardSession }
import from "./lib/wait.ts" { sleep }


node ClawInstance {
    has claw_id: str;
    has slug: str;
    has name: str;
    has created_at: str;
    has updated_at: str;
    has workspace_path: str;
    has soul_path: str;
    has starter_prompt_path: str;
    has inputs_path: str;
    has messages_path: str;
    has soul_md: str;
    has status: str = "workspace_ready";
    has provider: str = "none";
    has model: str = "";
    has provider_status: str = "missing";
    has provider_error: str = "";
    has starter_prompt: str = "";
    has operator_notes: str = "";
    has last_action: str = "Workspace provisioned on this server.";
    has last_error: str = "";
    has message_count: int = 0;
    has deleted_at: str = "";
}


obj ClawInstanceView {
    has id: str;
    has claw_id: str;
    has slug: str;
    has name: str;
    has created_at: str;
    has updated_at: str;
    has workspace_path: str;
    has soul_path: str;
    has starter_prompt_path: str;
    has inputs_path: str;
    has messages_path: str;
    has soul_md: str;
    has status: str;
    has provider: str = "none";
    has model: str = "";
    has provider_status: str = "missing";
    has provider_error: str = "";
    has starter_prompt: str = "";
    has operator_notes: str = "";
    has last_action: str = "";
    has last_error: str = "";
    has message_count: int = 0;
    has deleted_at: str = "";
}


obj ClawMessageView {
    has role: str;
    has content: str;
    has created_at: str;
    has client_label: str = "";
}


obj OpenClawHostView {
    has command_available: bool = False;
    has binary_path: str = "";
    has start_command: str = "";
    has stop_command: str = "";
    has healthcheck_command: str = "";
    has service_label: str = "LaunchAgent";
    has service_loaded: bool = False;
    has service_status: str = "unavailable";
    has service_state: str = "";
    has pid: int = 0;
    has gateway_host: str = "127.0.0.1";
    has gateway_port: int = 18789;
    has rpc_url: str = "";
    has healthy: bool = False;
    has last_action: str = "";
    has last_error: str = "";
    has raw_status: str = "";
}


node PairingSession {
    has token: str;
    has host_label: str;
    has created_at: str;
    has updated_at: str;
    has state: str = "waiting";
    has host_joined_at: str = "";
    has host_last_seen_at: str = "";
    has opened_at: str = "";
    has approved_at: str = "";
    has rejected_at: str = "";
    has phone_label: str = "";
    has phone_joined_at: str = "";
    has phone_last_seen_at: str = "";
    has browser_label: str = "";
    has last_action: str = "Laptop session created. Waiting for phone.";
    has visit_count: int = 0;
    has phone_user_id: str = "";
    has phone_workspace_path: str = "";
    has phone_soul_path: str = "";
    has phone_starter_prompt_path: str = "";
    has phone_inputs_path: str = "";
    has phone_messages_path: str = "";
    has phone_soul_md: str = "";
    has phone_starter_prompt: str = "";
    has phone_message_count: int = 0;
}


obj PairingSessionView {
    has id: str;
    has token: str;
    has host_label: str;
    has created_at: str;
    has updated_at: str;
    has state: str;
    has host_joined_at: str = "";
    has host_last_seen_at: str = "";
    has opened_at: str = "";
    has approved_at: str = "";
    has rejected_at: str = "";
    has phone_label: str = "";
    has phone_joined_at: str = "";
    has phone_last_seen_at: str = "";
    has browser_label: str = "";
    has last_action: str = "";
    has visit_count: int = 0;
    has phone_user_id: str = "";
    has phone_workspace_path: str = "";
    has phone_soul_path: str = "";
    has phone_starter_prompt_path: str = "";
    has phone_inputs_path: str = "";
    has phone_messages_path: str = "";
    has phone_soul_md: str = "";
    has phone_starter_prompt: str = "";
    has phone_message_count: int = 0;
}


def now_utc() -> str {
    return datetime.now(timezone.utc).isoformat();
}


def clean_label(value: str, fallback: str) -> str {
    cleaned = value.strip();
    return cleaned if cleaned else fallback;
}


def default_soul_md(name: str) -> str {
    clean_name = clean_label(name, "Demo Claw");
    return (
        f"# {clean_name}\n\n"
        "You are a concise, reliable demo Claw.\n\n"
        "Goals:\n"
        "- answer clearly\n"
        "- keep messages short unless asked for detail\n"
        "- stay grounded in the provided workspace files\n"
    );
}


def slugify(value: str) -> str {
    base = value.strip().lower();
    chars: list[str] = [];
    last_dash = False;

    for char in base {
        if char.isalnum() {
            chars.append(char);
            last_dash = False;
        } elif not last_dash {
            chars.append("-");
            last_dash = True;
        }
    }

    slug = "".join(chars).strip("-");
    return slug if slug else "claw";
}


def to_claw_view(instance: ClawInstance) -> ClawInstanceView {
    return ClawInstanceView(
        id=jid(instance),
        claw_id=instance.claw_id,
        slug=instance.slug,
        name=instance.name,
        status=instance.status,
        created_at=instance.created_at,
        updated_at=instance.updated_at,
        workspace_path=instance.workspace_path,
        soul_path=instance.soul_path,
        starter_prompt_path=instance.starter_prompt_path,
        inputs_path=instance.inputs_path,
        messages_path=instance.messages_path,
        soul_md=instance.soul_md,
        starter_prompt=instance.starter_prompt,
        operator_notes=instance.operator_notes,
        last_action=instance.last_action,
        provider=instance.provider,
        model=instance.model,
        provider_status=instance.provider_status,
        provider_error=instance.provider_error,
        last_error=instance.last_error,
        message_count=instance.message_count,
        deleted_at=instance.deleted_at,
    );
}


def find_claw_instance(claw_id: str) -> ClawInstance | None {
    for instance in [root-->][?:ClawInstance] {
        if instance.claw_id == claw_id {
            return instance;
        }
    }
    return None;
}


def to_claw_message_view(item: any) -> ClawMessageView {
    return ClawMessageView(
        role=item["role"],
        content=item["content"],
        created_at=item["created_at"],
        client_label=item["client_label"] if "client_label" in item else "",
    );
}


def to_openclaw_host_view(item: any) -> OpenClawHostView {
    return OpenClawHostView(
        command_available=item["command_available"] if "command_available" in item else False,
        binary_path=item["binary_path"] if "binary_path" in item else "",
        start_command=item["start_command"] if "start_command" in item else "",
        stop_command=item["stop_command"] if "stop_command" in item else "",
        healthcheck_command=item["healthcheck_command"] if "healthcheck_command" in item else "",
        service_label=item["service_label"] if "service_label" in item else "LaunchAgent",
        service_loaded=item["service_loaded"] if "service_loaded" in item else False,
        service_status=item["service_status"] if "service_status" in item else "unavailable",
        service_state=item["service_state"] if "service_state" in item else "",
        pid=item["pid"] if "pid" in item else 0,
        gateway_host=item["gateway_host"] if "gateway_host" in item else "127.0.0.1",
        gateway_port=item["gateway_port"] if "gateway_port" in item else 18789,
        rpc_url=item["rpc_url"] if "rpc_url" in item else "",
        healthy=item["healthy"] if "healthy" in item else False,
        last_action=item["last_action"] if "last_action" in item else "",
        last_error=item["last_error"] if "last_error" in item else "",
        raw_status=item["raw_status"] if "raw_status" in item else "",
    );
}


def sync_claw_provider(instance: ClawInstance) -> None {
    config = provider_config();
    instance.provider = config["provider"];
    instance.model = config["model"];
    instance.provider_status = config["provider_status"];
    instance.provider_error = config["provider_error"];
}


"""Return the local singleton OpenClaw host status for this Mac."""
def:pub get_openclaw_host_status(require_rpc: bool = False) -> OpenClawHostView {
    return to_openclaw_host_view(inspect_openclaw_gateway(require_rpc));
}


"""Start the local singleton OpenClaw host on this Mac."""
def:pub start_openclaw_host() -> OpenClawHostView {
    return to_openclaw_host_view(start_openclaw_gateway());
}


"""Stop the local singleton OpenClaw host on this Mac."""
def:pub stop_openclaw_host() -> OpenClawHostView {
    return to_openclaw_host_view(stop_openclaw_gateway());
}


"""Suggest the best phone access origin for this Mac and port."""
def:pub get_default_phone_access_origin(port: str = "") -> str {
    return preferred_phone_access_origin(port);
}


def to_view(session: PairingSession) -> PairingSessionView {
    return PairingSessionView(
        id=jid(session),
        token=session.token,
        host_label=session.host_label,
        state=session.state,
        created_at=session.created_at,
        updated_at=session.updated_at,
        host_joined_at=session.host_joined_at,
        host_last_seen_at=session.host_last_seen_at,
        opened_at=session.opened_at,
        approved_at=session.approved_at,
        rejected_at=session.rejected_at,
        phone_label=session.phone_label,
        phone_joined_at=session.phone_joined_at,
        phone_last_seen_at=session.phone_last_seen_at,
        browser_label=session.browser_label,
        last_action=session.last_action,
        visit_count=session.visit_count,
        phone_user_id=session.phone_user_id,
        phone_workspace_path=session.phone_workspace_path,
        phone_soul_path=session.phone_soul_path,
        phone_starter_prompt_path=session.phone_starter_prompt_path,
        phone_inputs_path=session.phone_inputs_path,
        phone_messages_path=session.phone_messages_path,
        phone_soul_md=session.phone_soul_md,
        phone_starter_prompt=session.phone_starter_prompt,
        phone_message_count=session.phone_message_count,
    );
}


def find_session(token: str) -> PairingSession | None {
    for session in [root-->][?:PairingSession] {
        if session.token == token {
            return session;
        }
    }
    return None;
}


def ensure_phone_user_workspace(session: PairingSession, phone_label: str, now: str) -> None {
    if session.phone_user_id and session.phone_workspace_path {
        return;
    }

    user_id = str(uuid4());
    clean_phone = clean_label(phone_label, session.phone_label or "Phone user");
    files = provision_phone_user_workspace(
        user_id,
        slugify(clean_phone),
        clean_phone,
        session.host_label,
        now,
    );

    session.phone_user_id = user_id;
    session.phone_workspace_path = files["workspace_path"];
    session.phone_soul_path = files["soul_path"];
    session.phone_starter_prompt_path = files["starter_prompt_path"];
    session.phone_inputs_path = files["inputs_path"];
    session.phone_messages_path = files["messages_path"];
    session.phone_soul_md = files["soul_md"];
    session.phone_starter_prompt = files["starter_prompt"];
    session.phone_message_count = 0;
}


"""Provision a local Claw workspace on this server for testing."""
def:pub create_claw_instance(
    name: str = "Demo Claw",
    soul_md: str = "",
    starter_prompt: str = "",
    operator_notes: str = "",
) -> ClawInstanceView | None {
    host = ensure_openclaw_gateway();
    if not host["healthy"] {
        return None;
    }

    now = now_utc();
    clean_name = clean_label(name, "Demo Claw");
    slug = slugify(clean_name);
    claw_id = str(uuid4());
    soul_text = soul_md.strip() if soul_md.strip() else default_soul_md(clean_name);
    config = provider_config();
    files = provision_workspace(
        claw_id,
        slug,
        clean_name,
        soul_text,
        starter_prompt.strip(),
        operator_notes.strip(),
        now,
    );

    instance: ClawInstance = root ++> ClawInstance(
        claw_id=claw_id,
        slug=slug,
        name=clean_name,
        created_at=now,
        updated_at=now,
        workspace_path=files["workspace_path"],
        soul_path=files["soul_path"],
        starter_prompt_path=files["starter_prompt_path"],
        inputs_path=files["inputs_path"],
        messages_path=files["messages_path"],
        soul_md=soul_text,
        provider=config["provider"],
        model=config["model"],
        provider_status=config["provider_status"],
        provider_error=config["provider_error"],
        starter_prompt=starter_prompt.strip(),
        operator_notes=operator_notes.strip(),
        last_action=(
            "Workspace provisioned on this server. Shared OpenClaw host is ready."
            if config["provider_status"] == "configured"
            else "Workspace provisioned on this server. Shared OpenClaw host is ready, but provider setup still needs work."
        ),
        last_error=config["provider_error"],
    );

    return to_claw_view(instance);
}


"""Return non-deleted Claw instances, newest first."""
def:pub get_claw_instances(include_deleted: bool = False) -> list[ClawInstanceView] {
    instances: list[ClawInstanceView] = [];
    for instance in [root-->][?:ClawInstance] {
        if not include_deleted and instance.deleted_at {
            continue;
        }
        instances = [to_claw_view(instance)] + instances;
    }
    return instances;
}


"""Return a single Claw instance by id."""
def:pub get_claw_instance(claw_id: str) -> ClawInstanceView | None {
    instance = find_claw_instance(claw_id);
    if not instance or instance.deleted_at {
        return None;
    }
    sync_claw_provider(instance);
    return to_claw_view(instance);
}


"""Return the saved transcript for a Claw workspace."""
def:pub get_claw_messages(claw_id: str) -> list[ClawMessageView] {
    instance = find_claw_instance(claw_id);
    if not instance or instance.deleted_at {
        return [];
    }

    messages: list[ClawMessageView] = [];
    for item in get_messages(instance.workspace_path) {
        messages.append(to_claw_message_view(item));
    }
    instance.message_count = len(messages);
    return messages;
}


"""Send a message to the configured provider for a Claw workspace."""
def:pub send_claw_message(
    claw_id: str,
    message: str,
    client_label: str = "Operator",
) -> ClawInstanceView | None {
    instance = find_claw_instance(claw_id);
    if not instance or instance.deleted_at {
        return None;
    }

    sync_claw_provider(instance);
    now = now_utc();
    result = talk_with_provider(
        instance.workspace_path,
        instance.soul_md,
        instance.starter_prompt,
        message,
        now,
        instance.provider,
        instance.model,
        clean_label(client_label, "Operator"),
    );

    instance.updated_at = now;
    if result["ok"] {
        instance.message_count = len(result["messages"]);
        instance.status = "chat_ready";
        instance.last_action = "Claw responded to a live message.";
        instance.last_error = "";
    } else {
        instance.status = "provider_error";
        instance.last_action = "Claw could not answer the last message.";
        instance.last_error = result["error"];
    }

    return to_claw_view(instance);
}


"""Delete a provisioned Claw workspace and hide it from the admin list."""
def:pub delete_claw_instance(claw_id: str) -> ClawInstanceView | None {
    instance = find_claw_instance(claw_id);
    if not instance or instance.deleted_at {
        return None;
    }

    delete_workspace(instance.workspace_path);

    now = now_utc();
    instance.status = "deleted";
    instance.deleted_at = now;
    instance.updated_at = now;
    instance.last_action = "Workspace deleted from this server.";

    return to_claw_view(instance);
}


def close_open_sessions(now: str) -> None {
    for session in [root-->][?:PairingSession] {
        if session.state == "waiting" or session.state == "joining" or session.state == "shared" {
            session.state = "superseded";
            session.updated_at = now;
            session.last_action = "Replaced by a newer pairing session";
        }
    }
}


"""Create a new local pairing session."""
def:pub create_pairing_session(host_label: str = "Local desktop") -> PairingSessionView {
    now = now_utc();
    close_open_sessions(now);
    session: PairingSession = root ++> PairingSession(
        token=str(uuid4()),
        host_label=clean_label(host_label, "Local desktop"),
        created_at=now,
        updated_at=now,
        host_joined_at=now,
        host_last_seen_at=now,
    );
    return to_view(session);
}


"""Return all pairing sessions, newest first."""
def:pub get_pairing_sessions() -> list[PairingSessionView] {
    sessions: list[PairingSessionView] = [];
    for session in [root-->][?:PairingSession] {
        sessions = [to_view(session)] + sessions;
    }
    return sessions;
}


"""Return a pairing session by token."""
def:pub get_pairing_session(token: str) -> PairingSessionView | None {
    session = find_session(token);
    return to_view(session) if session else None;
}


"""Return the saved chat transcript for a phone session."""
def:pub get_pairing_chat_messages(token: str) -> list[ClawMessageView] {
    session = find_session(token);
    if not session or not session.phone_workspace_path {
        return [];
    }

    messages: list[ClawMessageView] = [];
    for item in get_messages(session.phone_workspace_path) {
        messages.append(to_claw_message_view(item));
    }
    session.phone_message_count = len(messages);
    return messages;
}


"""Send a message from the paired phone session."""
def:pub send_pairing_chat_message(
    token: str,
    message: str,
    client_label: str = "Phone user",
) -> PairingSessionView | None {
    session = find_session(token);
    if not session or session.state != "shared" or not session.phone_workspace_path {
        return None;
    }

    sync_host = ensure_openclaw_gateway();
    if not sync_host["healthy"] {
        session.last_action = "Phone chat could not start because the shared OpenClaw host is not ready.";
        session.updated_at = now_utc();
        return to_view(session);
    }

    config = provider_config();
    now = now_utc();
    result = talk_with_provider(
        session.phone_workspace_path,
        session.phone_soul_md,
        session.phone_starter_prompt,
        message,
        now,
        config["provider"],
        config["model"],
        clean_label(client_label, session.phone_label or "Phone user"),
    );

    session.updated_at = now;
    if result["ok"] {
        session.phone_message_count = len(result["messages"]);
        session.last_action = "Phone session chat received a fresh reply.";
    } else {
        session.last_action = "Phone session chat failed to get a reply.";
    }
    return to_view(session);
}


"""Mark that the laptop is attached to the shared session."""
def:pub touch_host_session(
    token: str,
    host_label: str = "",
) -> PairingSessionView | None {
    session = find_session(token);
    if not session {
        return None;
    }

    now = now_utc();
    cleaned_host = host_label.strip();

    if cleaned_host {
        session.host_label = cleaned_host;
    }
    if not session.host_joined_at {
        session.host_joined_at = now;
    }

    session.host_last_seen_at = now;

    if session.state == "waiting" {
        session.last_action = "Laptop is ready for phone pairing";
    } elif session.state == "joining" {
        session.last_action = "Laptop is waiting for phone approval";
    } elif session.state == "shared" {
        session.last_action = "Laptop and phone are attached to the same session";
    }

    session.updated_at = now;
    return to_view(session);
}


"""Mark that a phone opened the pairing link."""
def:pub mark_pairing_opened(
    token: str,
    phone_label: str = "",
    browser_label: str = "",
) -> PairingSessionView | None {
    session = find_session(token);
    if not session {
        return None;
    }

    now = now_utc();
    session.visit_count += 1;

    cleaned_phone = phone_label.strip();
    cleaned_browser = browser_label.strip();

    if cleaned_phone {
        session.phone_label = cleaned_phone;
    }
    if cleaned_browser {
        session.browser_label = cleaned_browser;
    }
    if not session.phone_joined_at {
        session.phone_joined_at = now;
    }
    session.phone_last_seen_at = now;

    if session.state == "waiting" {
        session.state = "joining";
        session.opened_at = now;
        session.last_action = "Phone opened the laptop pairing session";
    } elif session.state == "joining" {
        session.last_action = "Phone refreshed the laptop pairing session";
    } elif session.state == "shared" {
        session.last_action = "Phone is attached to the shared laptop session";
    }

    session.updated_at = now;
    return to_view(session);
}


"""Approve a pairing session from the phone page."""
def:pub approve_pairing_session(
    token: str,
    phone_label: str = "",
    browser_label: str = "",
) -> PairingSessionView | None {
    session = find_session(token);
    if not session {
        return None;
    }

    now = now_utc();
    session.phone_label = clean_label(phone_label, session.phone_label or "Mobile browser");

    cleaned_browser = browser_label.strip();
    if cleaned_browser {
        session.browser_label = cleaned_browser;
    }

    if session.state != "declined" and session.state != "superseded" {
        if not session.opened_at {
            session.opened_at = now;
        }
        if not session.phone_joined_at {
            session.phone_joined_at = now;
        }
        ensure_phone_user_workspace(session, session.phone_label, now);
        session.phone_last_seen_at = now;
        session.state = "shared";
        session.approved_at = now;
        session.last_action = "Laptop and phone are now on the same session";
    }

    session.updated_at = now;
    return to_view(session);
}


"""Reject a pairing session from the phone page."""
def:pub reject_pairing_session(
    token: str,
    phone_label: str = "",
    browser_label: str = "",
) -> PairingSessionView | None {
    session = find_session(token);
    if not session {
        return None;
    }

    now = now_utc();

    cleaned_phone = phone_label.strip();
    cleaned_browser = browser_label.strip();

    if cleaned_phone {
        session.phone_label = cleaned_phone;
    }
    if cleaned_browser {
        session.browser_label = cleaned_browser;
    }
    if not session.phone_joined_at {
        session.phone_joined_at = now;
    }
    session.phone_last_seen_at = now;

    if session.state != "shared" and session.state != "superseded" {
        if not session.opened_at {
            session.opened_at = now;
        }
        session.state = "declined";
        session.rejected_at = now;
        session.last_action = "Phone declined to join the laptop session";
    }

    session.updated_at = now;
    return to_view(session);
}


def token_from_path(pathname: str) -> str {
    parts = [part for part in pathname.split("/") if part];
    if len(parts) >= 2 and parts[0] == "pair" {
        return parts[1];
    }
    return "";
}


def build_pair_url(origin: str, token: str) -> str {
    return buildPairUrl(origin, token);
}


def short_token(token: str) -> str {
    if len(token) <= 14 {
        return token;
    }
    return token[0:8] + "..." + token[-4:];
}


def pretty_stamp(value: str) -> str {
    if not value {
        return "Waiting";
    }
    text = value.replace("T", " ");
    text = text.replace("+00:00", "");
    return text[0:19] + " UTC" if len(text) >= 19 else text;
}


def state_label(state: str) -> str {
    match state {
        case "waiting":
            return "Waiting";
        case "joining":
            return "Joining";
        case "shared":
            return "Shared";
        case "declined":
            return "Declined";
        case "superseded":
            return "Superseded";
        case _:
            return state;
    }
}


def state_class(state: str) -> str {
    return "status-pill status-" + state;
}


def claw_status_label(status: str) -> str {
    match status {
        case "workspace_ready":
            return "Workspace ready";
        case "chat_ready":
            return "Chat ready";
        case "provider_error":
            return "Provider error";
        case "deleted":
            return "Deleted";
        case _:
            return status.replace("_", " ");
    }
}


def compact_state_label(state: str) -> str {
    match state {
        case "waiting":
            return "Ready to scan";
        case "joining":
            return "Phone is opening";
        case "shared":
            return "Connected";
        case "declined":
            return "Phone declined";
        case "superseded":
            return "Older code";
        case _:
            return state_label(state);
    }
}


def claw_status_class(status: str) -> str {
    return "status-pill status-claw-" + status;
}


def openclaw_host_label(host: any) -> str {
    if not host or not host.command_available {
        return "CLI missing";
    }
    if host.healthy {
        return "Running";
    }
    if host.service_loaded or host.pid > 0 {
        return "Starting";
    }
    return "Stopped";
}


def openclaw_host_class(host: any) -> str {
    if not host or not host.command_available {
        return "status-pill status-host-unavailable";
    }
    if host.healthy {
        return "status-pill status-host-running";
    }
    if host.service_loaded or host.pid > 0 {
        return "status-pill status-host-warming";
    }
    return "status-pill status-host-stopped";
}


def default_soul_template(name: str) -> str {
    clean_name = name.strip() or "Demo Claw";
    return (
        "# " + clean_name + "\n\n"
        + "You are a concise, reliable demo Claw.\n\n"
        + "Goals:\n"
        + "- answer clearly\n"
        + "- keep messages short unless asked for detail\n"
        + "- stay grounded in the provided workspace files\n"
    );
}


def ClawAdmin() -> any {
    has instances: list = [];
    has current_instance: any = None;
    has host_status: any = None;
    has messages: list = [];
    has loading: bool = True;
    has host_loading: bool = True;
    has host_busy: bool = False;
    has creating: bool = False;
    has sending: bool = False;
    has deleting_id: str = "";
    has name_input: str = "Demo Claw";
    has starter_prompt_input: str = "# Starter prompt\n\nUse the workspace files as the first source of truth.\n";
    has operator_notes_input: str = "Provisioned from Jacuzzi admin dashboard for local demo testing.";
    has soul_input: str = default_soul_template("Demo Claw");
    has chat_input: str = "Give me a one-sentence summary of this Claw workspace.";
    has notice: str = "";
    async def load_host_status(require_rpc: bool = False) {
        host_loading = True;
        host_status = await get_openclaw_host_status(require_rpc);
        host_loading = False;
    }

    async def refresh_current_messages() {
        if current_instance {
            messages = await get_claw_messages(current_instance.claw_id);
        } else {
            messages = [];
        }
    }

    async def load_instances(selected_id: str = "") {
        loading = True;
        data = await get_claw_instances();
        instances = data;

        preferred_id = selected_id;
        if not preferred_id and current_instance {
            preferred_id = current_instance.claw_id;
        }

        target: ClawInstanceView | None = None;
        if preferred_id {
            for item in data {
                if item.claw_id == preferred_id {
                    target = item;
                    break;
                }
            }
        }

        if not target and len(data) > 0 {
            target = data[0];
        }

        current_instance = target;
        if target is not None {
            messages = await get_claw_messages(target.claw_id);
        } else {
            messages = [];
        }
        loading = False;
    }

    async def start_host() {
        host_busy = True;
        host_status = await start_openclaw_host();
        host_loading = False;
        notice = host_status.last_action if host_status else "OpenClaw host start finished.";
        host_busy = False;
    }

    async def stop_host() {
        host_busy = True;
        host_status = await stop_openclaw_host();
        host_loading = False;
        notice = host_status.last_action if host_status else "OpenClaw host stop finished.";
        host_busy = False;
    }

    async def provision_instance() {
        creating = True;
        host_status = await start_openclaw_host();

        instance = await create_claw_instance(
            name_input,
            soul_input,
            starter_prompt_input,
            operator_notes_input,
        );
        if not instance {
            notice = (
                host_status.last_error
                if host_status and host_status.last_error
                else "Claw workspace was not created because the shared OpenClaw host is not ready."
            );
            creating = False;
            return;
        }
        instances = [instance] + instances;
        current_instance = instance;
        messages = [];
        notice = "Claw workspace provisioned on this server.";
        creating = False;
    }

    async def choose_instance(claw_id: str) {
        instance = await get_claw_instance(claw_id);
        current_instance = instance;
        await refresh_current_messages();
        notice = "Showing provisioned Claw instance details.";
    }

    async def delete_instance(claw_id: str) {
        deleting_id = claw_id;
        removed = await delete_claw_instance(claw_id);
        if removed {
            remaining = [item for item in instances if item.claw_id != claw_id];
            instances = remaining;

            if current_instance and current_instance.claw_id == claw_id {
                current_instance = remaining[0] if len(remaining) > 0 else None;
            }

            if current_instance {
                messages = await get_claw_messages(current_instance.claw_id);
            } else {
                messages = [];
            }
            notice = "Claw workspace deleted from this server.";
        }
        deleting_id = "";
    }

    async def send_message() {
        if not current_instance or not chat_input.strip() {
            return;
        }

        sending = True;
        updated = await send_claw_message(current_instance.claw_id, chat_input, "Laptop operator");
        current_instance = updated;
        await refresh_current_messages();
        notice = (
            "Claw answered from the configured provider."
            if updated and updated.status != "provider_error"
            else "Claw could not answer. Check provider configuration on the host."
        );
        sending = False;
    }

    async can with entry {
        prepareJacClientSession();
        await load_host_status();
        await load_instances();
    }

    return <section class="admin-stack">
        <section class="panel admin-panel">
            <div class="panel-head">
                <div>
                    <p class="eyebrow">OpenClaw</p>
                    <h2>Shared host on this Mac</h2>
                </div>
                <span class={openclaw_host_class(host_status)}>{openclaw_host_label(host_status)}</span>
            </div>
            <div class="host-grid">
                <div class="panel inset-panel host-panel">
                    <p class="host-panel__lead">
                        Jacuzzi uses one local OpenClaw gateway on this laptop. Every provisioned workspace shares that same host.
                    </p>
                    <div class="button-row">
                        <button class="primary-btn" onClick={start_host} disabled={host_busy or (host_status and host_status.healthy)}>
                            {"Starting..." if host_busy and (not host_status or not host_status.healthy) else "Start host"}
                        </button>
                        <button class="ghost-btn" onClick={stop_host} disabled={host_busy or not host_status or not host_status.service_loaded}>
                            {"Stopping..." if host_busy and host_status and host_status.service_loaded else "Stop host"}
                        </button>
                        <button class="ghost-btn" onClick={lambda () { load_host_status(); }} disabled={host_busy or host_loading}>
                            Refresh status
                        </button>
                    </div>
                    {(
                        <p class="inline-note">Checking the local OpenClaw gateway on this Mac.</p>
                    ) if host_loading else None}
                    {(
                        <p class="inline-note">
                            {host_status.last_action}
                        </p>
                    ) if (host_status and host_status.last_action) else None}
                    {(
                        <p class="inline-note">{host_status.last_error}</p>
                    ) if (host_status and host_status.last_error) else None}
                </div>

                <div class="panel inset-panel host-detail-panel">
                    <div class="facts-list">
                        <div class="fact-row">
                            <span>CLI</span>
                            <strong>{host_status.binary_path if host_status else "Checking..."}</strong>
                        </div>
                        <div class="fact-row">
                            <span>Service</span>
                            <strong>{host_status.service_label if host_status else "Checking..."}</strong>
                        </div>
                        <div class="fact-row">
                            <span>Status</span>
                            <strong>{openclaw_host_label(host_status)}</strong>
                        </div>
                        <div class="fact-row">
                            <span>PID</span>
                            <strong>{str(host_status.pid) if host_status and host_status.pid > 0 else "Not running"}</strong>
                        </div>
                        <div class="fact-row">
                            <span>RPC</span>
                            <strong>{host_status.rpc_url if host_status and host_status.rpc_url else "Waiting for RPC"}</strong>
                        </div>
                        <div class="fact-row">
                            <span>Port</span>
                            <strong>{str(host_status.gateway_port) if host_status else "18789"}</strong>
                        </div>
                    </div>
                    {(
                        <div class="instance-preview">
                            <p class="copy-label">Health command</p>
                            <pre class="copy-block copy-block--scroll">{host_status.healthcheck_command}</pre>
                        </div>
                    ) if host_status else None}
                </div>
            </div>
        </section>

        <section class="panel admin-panel">
            <div class="panel-head">
                <div>
                    <p class="eyebrow">Admin</p>
                    <h2>Create Claw on this server</h2>
                </div>
            </div>
            <div class="admin-grid">
                <div class="panel inset-panel provision-panel">
                    <label class="field">
                        <span class="field__label">Claw name</span>
                        <input
                            class="text-input"
                            value={name_input}
                            onChange={lambda (e: any) { name_input = e.target.value; }}
                            placeholder="Demo Claw"
                        />
                    </label>
                    <label class="field">
                        <span class="field__label">Starter prompt</span>
                        <textarea
                            class="text-input text-area"
                            value={starter_prompt_input}
                            onChange={lambda (e: any) { starter_prompt_input = e.target.value; }}
                        />
                    </label>
                    <label class="field">
                        <span class="field__label">Operator notes</span>
                        <textarea
                            class="text-input text-area"
                            value={operator_notes_input}
                            onChange={lambda (e: any) { operator_notes_input = e.target.value; }}
                        />
                    </label>
                    <label class="field">
                        <span class="field__label">soul.md</span>
                        <textarea
                            class="text-input text-area text-area--code"
                            value={soul_input}
                            onChange={lambda (e: any) { soul_input = e.target.value; }}
                        />
                    </label>
                    <div class="button-row">
                        <button class="primary-btn" onClick={provision_instance} disabled={creating}>
                            {"Provisioning..." if creating else "Provision test claw"}
                        </button>
                        <button class="ghost-btn" onClick={lambda () { load_instances(current_instance.claw_id if current_instance else ""); }}>
                            Refresh list
                        </button>
                    </div>
                    {notice and <p class="inline-note">{notice}</p>}
                </div>

                <div class="panel inset-panel instance-detail-panel">
                    <div class="panel-head">
                        <div>
                            <p class="eyebrow">Selected</p>
                            <h2>{current_instance.name if current_instance else "No Claw selected"}</h2>
                        </div>
                        {(
                            <span class={claw_status_class(current_instance.status)}>
                                {claw_status_label(current_instance.status)}
                            </span>
                        ) if current_instance else None}
                    </div>
                    {(
                        <div class="facts-list">
                            <div class="fact-row">
                                <span>Claw id</span>
                                <strong>{short_token(current_instance.claw_id)}</strong>
                            </div>
                            <div class="fact-row">
                                <span>Workspace</span>
                                <strong>{current_instance.workspace_path}</strong>
                            </div>
                            <div class="fact-row">
                                <span>soul.md</span>
                                <strong>{current_instance.soul_path}</strong>
                            </div>
                            <div class="fact-row">
                                <span>Inputs</span>
                                <strong>{current_instance.inputs_path}</strong>
                            </div>
                            <div class="fact-row">
                                <span>Updated</span>
                                <strong>{pretty_stamp(current_instance.updated_at)}</strong>
                            </div>
                            <div class="fact-row">
                                <span>Provider</span>
                                <strong>{current_instance.provider or "Not configured"}</strong>
                            </div>
                            <div class="fact-row">
                                <span>Model</span>
                                <strong>{current_instance.model or "Not configured"}</strong>
                            </div>
                            <div class="fact-row">
                                <span>Messages</span>
                                <strong>{str(current_instance.message_count)}</strong>
                            </div>
                            <div class="fact-row">
                                <span>Shared host</span>
                                <strong>{openclaw_host_label(host_status)}</strong>
                            </div>
                        </div>
                    ) if current_instance else (
                        <p class="inline-note">Provision a test Claw to create a dedicated workspace on this server.</p>
                    )}
                    {(
                        <div class="instance-preview">
                            <p class="copy-label">Saved soul.md</p>
                            <pre class="copy-block copy-block--scroll">{current_instance.soul_md}</pre>
                        </div>
                    ) if current_instance else None}
                    {(
                        <div class="instance-preview">
                            <p class="copy-label">Provider status</p>
                            <p class="inline-note">
                                {(
                                    "Ready to talk."
                                ) if current_instance.provider_status == "configured" else (
                                    current_instance.provider_error or "Provider is not configured on the host."
                                )}
                            </p>
                        </div>
                    ) if current_instance else None}
                </div>
            </div>
        </section>

        <section class="panel admin-panel">
            <div class="panel-head">
                <div>
                    <p class="eyebrow">Chat</p>
                    <h2>Talk to the selected Claw</h2>
                </div>
                {(
                    <span class={claw_status_class(current_instance.status)}>
                        {claw_status_label(current_instance.status)}
                    </span>
                ) if current_instance else None}
            </div>
            {(
                <div class="chat-shell">
                    <div class="chat-log">
                        {[
                            <article class={"chat-message chat-message--" + message.role}>
                                <p class="chat-message__meta">
                                    {(message.client_label or message.role) + " · " + pretty_stamp(message.created_at)}
                                </p>
                                <p class="chat-message__body">{message.content}</p>
                            </article> for message in messages
                        ]}
                        {(
                            <p class="inline-note">No messages yet. Send a message from this panel to test the provider.</p>
                        ) if len(messages) == 0 else None}
                    </div>
                    <label class="field">
                        <span class="field__label">Message</span>
                        <textarea
                            class="text-input text-area"
                            value={chat_input}
                            onChange={lambda (e: any) { chat_input = e.target.value; }}
                            placeholder="Ask the Claw something real."
                        />
                    </label>
                    <div class="button-row">
                        <button class="primary-btn" onClick={send_message} disabled={sending or not current_instance}>
                            {"Sending..." if sending else "Send message"}
                        </button>
                        <button
                            class="ghost-btn"
                            onClick={lambda () { refresh_current_messages(); }}
                            disabled={not current_instance}
                        >
                            Refresh transcript
                        </button>
                    </div>
                    {(
                        <p class="inline-note">{current_instance.last_error}</p>
                    ) if (current_instance and current_instance.last_error) else None}
                </div>
            ) if current_instance else (
                <p class="inline-note">Select a Claw workspace first.</p>
            )}
        </section>

        <section class="panel history-panel">
            <div class="panel-head">
                <div>
                    <p class="eyebrow">Admin</p>
                    <h2>Provisioned Claw workspaces</h2>
                </div>
            </div>
            {[
                <div
                    key={instance.claw_id}
                    class={"instance-row " + ("instance-row--active" if current_instance and current_instance.claw_id == instance.claw_id else "")}
                >
                    <button class="instance-row__main" onClick={lambda () { choose_instance(instance.claw_id); }}>
                        <span class="instance-row__title">{instance.name}</span>
                        <span class={claw_status_class(instance.status)}>{claw_status_label(instance.status)}</span>
                        <span class="instance-row__meta">{instance.workspace_path}</span>
                        <span class="instance-row__meta">{pretty_stamp(instance.updated_at)}</span>
                    </button>
                    <button
                        class="ghost-btn"
                        onClick={lambda () { delete_instance(instance.claw_id); }}
                        disabled={deleting_id == instance.claw_id}
                    >
                        {"Deleting..." if deleting_id == instance.claw_id else "Delete"}
                    </button>
                </div> for instance in instances
            ]}
            {(
                <p class="inline-note">Loading provisioned Claw workspaces...</p>
            ) if loading else None}
            {(
                <p class="inline-note">No Claw workspaces provisioned yet.</p>
            ) if (not loading and len(instances) == 0) else None}
        </section>
    </section>;
}


def next_step_label(state: str, visit_count: int) -> str {
    match state {
        case "waiting":
            return "Scan the code with the phone." if visit_count == 0 else "Finish joining on the phone.";
        case "joining":
            return "Approve this session on the phone.";
        case "shared":
            return "Both devices are now linked.";
        case "declined":
            return "Start a new code if you want to try again.";
        case "superseded":
            return "Use the newest code on the laptop.";
        case _:
            return "Check the latest session state.";
    }
}


def session_is_closed(state: str) -> bool {
    return state == "declined" or state == "superseded";
}


def session_pair_url(session: any, origin: str) -> str {
    if not session or not origin {
        return "";
    }
    return build_pair_url(origin, session.token);
}


def session_qr_svg(session: any, origin: str) -> str {
    pair_url = session_pair_url(session, origin);
    return renderQrSvg(pair_url) if pair_url else "";
}


def Dashboard() -> any {
    has sessions: list = [];
    has current_session: any = None;
    has session_messages: list = [];
    has host_status: any = None;
    has host_label: str = "This laptop";
    has browser_origin: str = "";
    has pair_origin: str = "";
    has pair_origin_input: str = "";
    has loading: bool = True;
    has creating: bool = False;
    has chat_loading: bool = False;
    has sending_chat: bool = False;
    has session_chat_input: str = "Give me a quick status check and ask what we should do next.";
    has current_origin_local_only: bool = False;
    has action_note: str = "";
    has copy_note: str = "";
    has pair_origin_note: str = "";
    has show_debug: bool = False;
    async def load_host_summary(require_rpc: bool = True) {
        host_status = await get_openclaw_host_status(require_rpc);
    }

    async def refresh_session_messages(token: str = "") -> list {
        active_token = token if token else (current_session.token if current_session else "");
        if not active_token or not current_session or current_session.state != "shared" {
            session_messages = [];
            chat_loading = False;
            return [];
        }

        chat_loading = True;
        latest_messages = await get_pairing_chat_messages(active_token);
        session_messages = latest_messages;
        current_session.phone_message_count = len(latest_messages);
        chat_loading = False;
        return latest_messages;
    }

    async def sync_current_session(show_note: bool = False) -> any {
        if not current_session {
            return None;
        }

        previous_state = current_session.state;
        latest = await touch_host_session(current_session.token, host_label);
        if not latest {
            return None;
        }

        current_session = latest;
        sessions = [latest] + [item for item in sessions if item.token != latest.token];

        if latest.state == "shared" {
            await refresh_session_messages(latest.token);
            if previous_state != "shared" {
                action_note = "Phone connected. The live web chat is ready.";
            } elif show_note {
                action_note = "Latest session status loaded.";
            }
        } else {
            session_messages = [];
            if show_note {
                action_note = "Latest session status loaded.";
            }
        }

        watchDashboardSession(
            latest.token,
            latest.state,
            latest.phone_message_count,
            latest.visit_count,
            latest.phone_label,
        );

        return latest;
    }

    async def load_dashboard(selected_token: str = "", origin_override: str = "") -> any {
        loading = True;
        data = await get_pairing_sessions();

        if len(data) == 0 {
            await sleep(200);
            data = await get_pairing_sessions();
        }
        if len(data) == 0 {
            await sleep(400);
            data = await get_pairing_sessions();
        }
        if len(data) == 0 {
            await sleep(800);
            data = await get_pairing_sessions();
        }
        if len(data) == 0 {
            await sleep(1600);
            data = await get_pairing_sessions();
        }
        if len(data) == 0 {
            await sleep(3200);
            data = await get_pairing_sessions();
        }

        sessions = data;

        target: PairingSessionView | None = None;
        if selected_token {
            for item in data {
                if item.token == selected_token {
                    target = item;
                    break;
                }
            }
        }

        if not target and len(data) > 0 {
            target = data[0];
        }

        next_session: PairingSessionView | None = None;
        if target is not None {
            touched = await touch_host_session(target.token);
            next_session = (touched if touched else target) as PairingSessionView;
            current_session = next_session;
            if next_session.state == "shared" {
                await refresh_session_messages(next_session.token);
            } else {
                session_messages = [];
            }
            watchDashboardSession(
                next_session.token,
                next_session.state,
                next_session.phone_message_count,
                next_session.visit_count,
                next_session.phone_label,
            );
        } else {
            current_session = None;
            session_messages = [];
        }
        loading = False;
        return next_session;
    }

    async def create_session(auto_created: bool = False) -> any {
        creating = True;
        session = await create_pairing_session(host_label);
        current_session = session;
        loading = False;
        sessions = [session] + [item for item in sessions if item.token != session.token];
        session_messages = [];
        watchDashboardSession(session.token, session.state, session.phone_message_count, session.visit_count, session.phone_label);
        action_note = "" if auto_created else "A fresh phone code is ready.";
        copy_note = "";
        creating = False;
        return session;
    }

    async def refresh_dashboard() {
        await load_host_summary();
        if current_session {
            updated = await sync_current_session(True);
            if not updated {
                await load_dashboard();
                action_note = "Latest session status loaded.";
            }
        } else {
            await load_dashboard();
            action_note = "Latest session status loaded.";
        }
    }

    async def choose_session(token: str) {
        await load_dashboard(token);
        action_note = "Showing this saved session.";
    }

    async def send_session_chat() {
        if not current_session or current_session.state != "shared" or not session_chat_input.strip() {
            return;
        }

        sending_chat = True;
        updated = await send_pairing_chat_message(
            current_session.token,
            session_chat_input,
            host_label or current_session.host_label or "This laptop",
        );
        if updated {
            current_session = updated;
            sessions = [updated] + [item for item in sessions if item.token != updated.token];
        }
        latest_messages = await refresh_session_messages(current_session.token if current_session else "");
        if current_session {
            watchDashboardSession(
                current_session.token,
                current_session.state,
                len(latest_messages),
                current_session.visit_count,
                current_session.phone_label,
            );
        }
        action_note = "Shared session chat updated." if len(latest_messages) > 0 else "Shared session chat did not return a reply.";
        sending_chat = False;
    }

    async def copy_link() {
        if current_session {
            if not pair_origin {
                copy_note = "Open this page on the laptop Wi-Fi address first.";
                return;
            }
            copied = await copyText(session_pair_url(current_session, pair_origin));
            copy_note = "Pair link copied." if copied else "Copy failed.";
        }
    }

    async def copy_token() {
        if current_session {
            copied = await copyText(current_session.token);
            copy_note = "Token copied." if copied else "Copy failed.";
        }
    }

    async def save_pair_origin() {
        cleaned = storePairOrigin(pair_origin_input);
        if cleaned {
            if isLocalOnlyOrigin(cleaned) {
                clearStoredPairOrigin();
                pair_origin_note = "Use the laptop Wi-Fi address here, not localhost.";
                return;
            }
            pair_origin = cleaned;
            pair_origin_input = cleaned;
            pair_origin_note = "Phone access URL saved.";
            return;
        }
        pair_origin_note = "Enter the laptop Wi-Fi address, such as http://192.168.1.25:8000.";
    }

    async def reset_pair_origin() {
        clearStoredPairOrigin();
        pair_origin = getSuggestedPairOrigin();
        pair_origin_input = pair_origin;
        pair_origin_note = (
            "Phone access URL reset to this browser origin."
            if pair_origin
            else "Phone access URL cleared. Enter the laptop LAN origin for real phone scans."
        );
    }

    async can with entry {
        prepareJacClientSession();
        host = window.location.hostname;
        browser_origin = window.location.origin;
        current_port = window.location.port;
        host_label = "This laptop";
        current_origin_local_only = isCurrentOriginLocalOnly();
        saved_pair_origin = getSavedPairOrigin();
        suggested_pair_origin = getSuggestedPairOrigin();

        if saved_pair_origin and isLocalOnlyOrigin(saved_pair_origin) {
            clearStoredPairOrigin();
            saved_pair_origin = "";
        }

        initial_pair_origin = saved_pair_origin if saved_pair_origin else suggested_pair_origin;
        if initial_pair_origin and isLocalOnlyOrigin(initial_pair_origin) and not saved_pair_origin {
            initial_pair_origin = "";
        }

        if not initial_pair_origin {
            inferred_pair_origin = await get_default_phone_access_origin(current_port);
            if inferred_pair_origin and not isLocalOnlyOrigin(inferred_pair_origin) {
                pair_origin_note = "Using this Mac's Wi-Fi address for phone pairing.";
                initial_pair_origin = inferred_pair_origin;
            }
        }

        pair_origin = initial_pair_origin;
        pair_origin_input = initial_pair_origin;

        await load_host_summary();
        preferred_session_token = getActiveDashboardSessionToken();
        loaded_session = await load_dashboard(preferred_session_token, initial_pair_origin);

        if not loaded_session {
            await create_session(True);
        }
    }

    return <main class="app-shell">
        <section class="desktop-shell panel">
            <header class="desktop-topbar">
                <div class="desktop-brand">
                    <div class="desktop-brand__mark">J</div>
                    <div>
                        <p class="eyebrow">Jacuzzi</p>
                        <strong>OpenClaw Setup</strong>
                    </div>
                </div>
                <nav class="desktop-topbar__links">
                    <span>Setup</span>
                    <span>Status</span>
                    <span>Docs</span>
                </nav>
                    <div class="desktop-topbar__actions">
                        <button class="ghost-btn ghost-btn--icon" onClick={refresh_dashboard}>Refresh</button>
                        <button class="ghost-btn ghost-btn--icon debug-toggle" onClick={lambda () { show_debug = not show_debug; }}>
                            {"Show details" if not show_debug else "Hide details"}
                        </button>
                    </div>
            </header>

            <div class="desktop-layout">
                <aside class="desktop-sidebar">
                    <div>
                        <h2>Setup Flow</h2>
                        <p>Onboarding Progress</p>
                    </div>
                    <nav class="desktop-nav">
                        <div class="desktop-nav__item">
                            <span>01</span>
                            <strong>Profile</strong>
                        </div>
                        <div class="desktop-nav__item desktop-nav__item--active">
                            <span>02</span>
                            <strong>Connectivity</strong>
                        </div>
                        <div class="desktop-nav__item">
                            <span>03</span>
                            <strong>Logic</strong>
                        </div>
                        <div class="desktop-nav__item">
                            <span>04</span>
                            <strong>Review</strong>
                        </div>
                    </nav>
                    <button class="desktop-draft">Save Draft</button>
                </aside>

                <div class="desktop-content">
                    {(
                        <section class="celebration-shell">
                            <div class="celebration-orb">
                                <div class="celebration-orb__core">J</div>
                            </div>
                            <div class="celebration-copy">
                                <span class={state_class(current_session.state)}>{compact_state_label(current_session.state)}</span>
                                <h1>You're all set</h1>
                                <p class="hero-text">
                                    Your phone is connected and ready to chat. Jacuzzi is set up and the live session is waiting for the next instruction.
                                </p>
                            </div>
                            <div class="celebration-grid">
                                <article class="celebration-card">
                                    <p class="eyebrow">Phone</p>
                                    <h2>{current_session.phone_label or "Connected phone"}</h2>
                                    <p>{next_step_label(current_session.state, current_session.visit_count)}</p>
                                </article>
                                <article class="celebration-card celebration-card--soft">
                                    <p class="eyebrow">Session chat</p>
                                    <h2>{str(current_session.phone_message_count) + " messages" if current_session.phone_message_count > 0 else "Ready to start"}</h2>
                                    <p>The laptop and phone are now looking at the same live session transcript.</p>
                                </article>
                            </div>
                            <article class="celebration-chat panel inset-panel">
                                <div class="panel-head panel-head--compact">
                                    <div>
                                        <p class="eyebrow">Live chat</p>
                                        <h2>Shared session</h2>
                                    </div>
                                </div>
                                <div class="chat-shell celebration-chat__shell">
                                    <div class="chat-log celebration-chat__log">
                                        {[
                                            <article class={"chat-message chat-message--" + message.role}>
                                                <p class="chat-message__meta">
                                                    {(message.client_label or message.role) + " · " + pretty_stamp(message.created_at)}
                                                </p>
                                                <p class="chat-message__body">{message.content}</p>
                                            </article> for message in session_messages
                                        ]}
                                        {(
                                            <p class="inline-note">The shared chat will appear here as soon as the first message lands.</p>
                                        ) if (not chat_loading and len(session_messages) == 0) else None}
                                        {(
                                            <p class="inline-note">Loading the current shared chat.</p>
                                        ) if chat_loading else None}
                                    </div>
                                    <label class="field">
                                        <span class="field__label">Ask this session</span>
                                        <textarea
                                            class="text-input text-area"
                                            value={session_chat_input}
                                            onChange={lambda (e: any) { session_chat_input = e.target.value; }}
                                            placeholder="Send the next message from the web."
                                        />
                                    </label>
                                    <div class="button-row celebration-chat__actions">
                                        <button class="primary-btn" onClick={send_session_chat} disabled={sending_chat or chat_loading}>
                                            {"Sending..." if sending_chat else "Send message"}
                                        </button>
                                        <button class="ghost-btn" onClick={lambda () { refresh_session_messages(); }} disabled={sending_chat}>
                                            Refresh chat
                                        </button>
                                    </div>
                                </div>
                            </article>
                            <div class="celebration-actions">
                                <button class="primary-btn" onClick={lambda () { create_session(); }} disabled={creating}>
                                    {"Making code..." if creating else "Make a new code"}
                                </button>
                                <button class="ghost-btn" onClick={refresh_dashboard}>Refresh status</button>
                            </div>
                            {action_note and <p class="inline-note">{action_note}</p>}
                            {copy_note and <p class="inline-note">{copy_note}</p>}
                            <div class="progress-footer">
                                <span>Phone connected</span>
                                <span>Session live</span>
                                <span>Ready for chat</span>
                            </div>
                        </section>
                    ) if (current_session and current_session.state == "shared") else (
                        <section class="connect-shell">
                            <div class="connect-copy">
                                <p class="eyebrow">Step 2 of 4</p>
                                <h1>Sync your Jacuzzi</h1>
                                <p class="hero-text">
                                    Scan with your phone to complete setup. This will pair your mobile session and open a live chat right away.
                                </p>
                                <article class="qr-panel qr-card">
                                    <div class="qr-card__inner">
                                        {(
                                            <div class="qr-frame" dangerouslySetInnerHTML={{"__html": session_qr_svg(current_session, pair_origin)}} />
                                        ) if (current_session and session_pair_url(current_session, pair_origin)) else (
                                            <div class="qr-empty">
                                                <strong>No QR yet</strong>
                                                <p>
                                                    {(
                                                        "Save a phone ready address in operator view and the QR will appear here."
                                                    ) if not pair_origin else (
                                                        "Refresh this page or make a new code to load the pairing card."
                                                    )}
                                                </p>
                                            </div>
                                        )}
                                        <div class="qr-card__badge">
                                            {current_session and <span class={state_class(current_session.state)}>{compact_state_label(current_session.state)}</span>}
                                            <strong>
                                        {(
                                            "Waiting for connection..."
                                        ) if not current_session else (
                                            "Phone declined this code."
                                        ) if current_session.state == "declined" else (
                                            "This code was replaced by a newer one."
                                        ) if current_session.state == "superseded" else (
                                            "Waiting for connection..."
                                        ) if current_session.visit_count == 0 else (
                                            "Phone found. Finish joining on the phone."
                                        )}
                                            </strong>
                                        </div>
                                    </div>
                                </article>
                                <div class="qr-card__actions">
                                    <button class="primary-btn" onClick={copy_link} disabled={not current_session or not session_pair_url(current_session, pair_origin)}>
                                        Copy link
                                    </button>
                                    <button class="ghost-btn" onClick={lambda () { create_session(); }} disabled={creating}>
                                        {"Making code..." if creating else "Make new code"}
                                    </button>
                                </div>
                                {action_note and <p class="inline-note">{action_note}</p>}
                                {copy_note and <p class="inline-note">{copy_note}</p>}
                                {(
                                    <div class="origin-warning origin-warning--soft">
                                        <strong>{current_session.last_action or "This code is no longer active."}</strong>
                                        <p>{next_step_label(current_session.state, current_session.visit_count)}</p>
                                    </div>
                                ) if (current_session and session_is_closed(current_session.state)) else None}
                                {(
                                    <div class="origin-warning origin-warning--soft">
                                        <strong>Use the laptop Wi-Fi address before scanning</strong>
                                        <p>
                                            The code needs a phone ready address. Open operator view once to save the Wi-Fi URL for this laptop.
                                        </p>
                                    </div>
                                ) if (not pair_origin and current_origin_local_only) else None}
                            </div>

                            <div class="connect-visual">
                                <div class="mock-phone">
                                    <div class="mock-phone__screen">
                                        <div class="mock-phone__avatar">J</div>
                                        <div class="mock-phone__line mock-phone__line--wide" />
                                        <div class="mock-phone__line" />
                                        <div class="mock-phone__card" />
                                        <div class="mock-phone__card mock-phone__card--soft" />
                                        <div class="mock-phone__cta">
                                            {current_session.phone_label if current_session and current_session.phone_label else "Phone chat opens here"}
                                        </div>
                                    </div>
                                </div>
                                <div class="floating-status">
                                    <p class="eyebrow">Jacuzzi Status</p>
                                    <strong>{compact_state_label(current_session.state) if current_session else "Preparing"}</strong>
                                    <p>
                                        {(
                                            "The phone declined this code. Make a new one to try again."
                                        ) if (current_session and current_session.state == "declined") else (
                                            "This code was replaced. Use the newest one on the laptop."
                                        ) if (current_session and current_session.state == "superseded") else (
                                            "Waiting for a phone to scan the code."
                                        ) if not current_session or current_session.visit_count == 0 else (
                                            "The phone reached the session link and can join now."
                                        )}
                                    </p>
                                </div>
                            </div>
                        </section>
                    )}
                </div>
            </div>
        </section>

        {(
            <section class="details-shell panel details-shell--embedded">
                <div class="panel-head">
                    <div>
                        <p class="eyebrow">Operator details</p>
                        <h2>Network setup, history, and host controls</h2>
                    </div>
                </div>
                <div class="details-grid">
                    <section class="panel inset-panel support-panel">
                        <div class="panel-head panel-head--compact">
                            <div>
                                <p class="eyebrow">Network</p>
                                <h2>Pairing route</h2>
                            </div>
                        </div>
                        <label class="field">
                            <span class="field__label">Desktop label</span>
                            <input
                                class="text-input"
                                value={host_label}
                                onChange={lambda (e: any) { host_label = e.target.value; }}
                                placeholder="This laptop"
                            />
                        </label>
                        <label class="field">
                            <span class="field__label">Phone access URL</span>
                            <input
                                class="text-input"
                                value={pair_origin_input}
                                onChange={lambda (e: any) { pair_origin_input = e.target.value; }}
                                placeholder="http://192.168.1.25:8000"
                            />
                            <p class="field__hint">
                                {(
                                    "If the dashboard is on localhost, save the laptop Wi-Fi address here so the phone can open the code."
                                ) if current_origin_local_only else (
                                    "This becomes the QR target and copied link."
                                )}
                            </p>
                        </label>
                        <div class="button-row">
                            <button class="ghost-btn" onClick={save_pair_origin}>
                                Save phone URL
                            </button>
                            {(
                                <button class="ghost-btn" onClick={reset_pair_origin}>
                                    Use browser URL
                                </button>
                            ) if pair_origin != getSuggestedPairOrigin() else None}
                        </div>
                        {pair_origin_note and <p class="inline-note">{pair_origin_note}</p>}
                        {current_session and (
                            <div class="debug-panel">
                                <p class="copy-label">Pair URL</p>
                                <code class="copy-block">{session_pair_url(current_session, pair_origin)}</code>
                                <div class="button-row">
                                    <button class="ghost-btn" onClick={copy_link} disabled={not session_pair_url(current_session, pair_origin)}>
                                        Copy link
                                    </button>
                                    <button class="ghost-btn" onClick={copy_token}>
                                        Copy token
                                    </button>
                                </div>
                                <div class="facts-list">
                                    <div class="fact-row">
                                        <span>Token</span>
                                        <strong>{short_token(current_session.token)}</strong>
                                    </div>
                                    <div class="fact-row">
                                        <span>Created</span>
                                        <strong>{pretty_stamp(current_session.created_at)}</strong>
                                    </div>
                                    <div class="fact-row">
                                        <span>Phone opened link</span>
                                        <strong>{str(current_session.visit_count) if current_session.visit_count else "No"}</strong>
                                    </div>
                                </div>
                            </div>
                        )}
                    </section>

                    <section class="panel inset-panel history-panel">
                        <div class="panel-head panel-head--compact">
                            <div>
                                <p class="eyebrow">History</p>
                                <h2>Saved sessions</h2>
                            </div>
                        </div>
                        {[
                            <button
                                key={session.token}
                                class={"session-row " + ("session-row--active" if current_session and current_session.token == session.token else "")}
                                onClick={lambda () { choose_session(session.token); }}
                            >
                                <span class="session-row__token">{short_token(session.token)}</span>
                                <span class={state_class(session.state)}>{state_label(session.state)}</span>
                                <span class="session-row__meta">{session.host_label}</span>
                                <span class="session-row__meta">{pretty_stamp(session.updated_at)}</span>
                            </button> for session in sessions
                        ]}
                        {(
                            <p class="inline-note">Loading saved sessions...</p>
                        ) if loading else None}
                    </section>
                </div>
                <div class="operator-tools">
                    <ClawAdmin />
                </div>
            </section>
        ) if show_debug else None}
    </main>;
}


def PairPage(token: str) -> any {
    has session: any = None;
    has messages: list = [];
    has loading: bool = True;
    has chat_loading: bool = False;
    has submitting: bool = False;
    has sending_chat: bool = False;
    has phone_label: str = "";
    has browser_label: str = "";
    has chat_input: str = "Give me a quick status check and ask what I want to do next.";
    has notice: str = "";
    has show_debug: bool = False;
    async def refresh_messages() -> list {
        if session and session.state == "shared" and session.phone_workspace_path {
            chat_loading = True;
            latest_messages = await get_pairing_chat_messages(token);
            messages = latest_messages;
            chat_loading = False;
            return latest_messages;
        } else {
            messages = [];
            return [];
        }
    }

    async def load_session(mark_open: bool = False) {
        if mark_open {
            opened = await mark_pairing_opened(token, phone_label, browser_label);
            if opened {
                session = opened;
                await refresh_messages();
                loading = False;
                return;
            }
        }
        session = await get_pairing_session(token);
        await refresh_messages();
        loading = False;
    }

    async def approve() {
        submitting = True;
        session = await approve_pairing_session(token, phone_label, browser_label);
        await refresh_messages();
        notice = "Phone joined the shared laptop session.";
        submitting = False;
    }

    async def reject() {
        submitting = True;
        session = await reject_pairing_session(token, phone_label, browser_label);
        notice = "Phone declined to join this laptop session.";
        submitting = False;
    }

    async def refresh() {
        await load_session(True);
        notice = "Phone session refreshed from backend state.";
    }

    async def send_chat() {
        if not chat_input.strip() or not session or session.state != "shared" {
            return;
        }

        sending_chat = True;
        updated = await send_pairing_chat_message(token, chat_input, phone_label or browser_label or "Phone user");
        if updated {
            session = updated;
        }
        latest_messages = await refresh_messages();
        notice = "Phone session chat updated." if len(latest_messages) > 0 else "Phone session chat did not return a reply.";
        sending_chat = False;
    }

    async can with entry {
        prepareJacClientSession();
        profile = getClientProfile();
        phone_label = profile.deviceLabel;
        browser_label = profile.browserLabel;
        await load_session(True);
    }

    return <main class="phone-shell">
        <section class={"phone-card panel " + ("phone-card--success" if session and session.state == "shared" else "phone-card--closed" if session and (session.state == "declined" or session.state == "superseded") else "phone-card--setup")}>
            <p class="eyebrow">Jacuzzi</p>
            {(
                <div class="phone-loading">
                    <h1>Loading laptop session</h1>
                    <p>Checking the QR token and current backend state.</p>
                </div>
            ) if loading else None}

            {(
                <div class="phone-state">
                    <div class="panel-head">
                        <div>
                            <h1>This pairing link is not available.</h1>
                            <p class="hero-text">Open the latest laptop QR link from the desktop dashboard and try again.</p>
                        </div>
                    </div>
                    <div class="chat-shell chat-shell--session">
                        <div class="chat-log">
                            <article class="chat-message chat-message--assistant">
                                <p class="chat-message__meta">Jacuzzi</p>
                                <p class="chat-message__body">
                                    This code is missing or expired. Go back to the laptop and open the newest live session.
                                </p>
                            </article>
                        </div>
                        <div class="mobile-actions">
                            <button class="ghost-btn" onClick={refresh}>Check again</button>
                        </div>
                    </div>
                </div>
            ) if (not loading and not session) else None}

            {(
                <div class="phone-state">
                    <div class="panel-head">
                        <div>
                            <h1>Connect this phone</h1>
                            <p class="hero-text">
                                Name this phone, then connect it to the live session on this Mac.
                            </p>
                        </div>
                        <span class={state_class(session.state)}>{compact_state_label(session.state)}</span>
                    </div>

                    <div class="chat-shell chat-shell--session">
                        <div class="chat-log">
                            <article class="chat-message chat-message--assistant">
                                <p class="chat-message__meta">Jacuzzi</p>
                                <p class="chat-message__body">
                                    {"You are opening a live session from " + session.host_label + ". Name this phone and join when you are ready."}
                                </p>
                            </article>
                            <article class="chat-message chat-message--system">
                                <p class="chat-message__meta">Session</p>
                                <p class="chat-message__body">
                                    {next_step_label(session.state, session.visit_count)}
                                </p>
                            </article>
                            <article class="chat-message chat-message--system">
                                <p class="chat-message__meta">Laptop</p>
                                <p class="chat-message__body">{session.host_label}</p>
                            </article>
                        </div>
                        <div class="chat-composer-card">
                            <label class="field">
                                <span class="field__label">Phone label</span>
                                <input
                                    class="text-input"
                                    value={phone_label}
                                    onChange={lambda (e: any) { phone_label = e.target.value; }}
                                    placeholder="Chris's iPhone"
                                />
                            </label>

                            <p class="phone-helper">
                                {"Browser reported as " + (browser_label or "Unknown browser") + "."}
                            </p>

                            <div class="mobile-actions">
                                <button class="primary-btn" onClick={approve} disabled={submitting}>
                                    {"Saving..." if submitting else "Join shared session"}
                                </button>
                                <button class="ghost-btn" onClick={reject} disabled={submitting}>
                                    Not this phone
                                </button>
                                <button class="ghost-btn" onClick={refresh} disabled={submitting}>
                                    Refresh
                                </button>
                            </div>
                        </div>
                    </div>
                    <button class="ghost-btn debug-toggle" onClick={lambda () { show_debug = not show_debug; }}>
                        {"Show details" if not show_debug else "Hide details"}
                    </button>
                    {(
                        <div class="debug-panel">
                            <div class="facts-list facts-list--stacked">
                                <div class="fact-row">
                                    <span>Token</span>
                                    <strong>{short_token(session.token)}</strong>
                                </div>
                                <div class="fact-row">
                                    <span>Laptop last seen</span>
                                    <strong>{pretty_stamp(session.host_last_seen_at)}</strong>
                                </div>
                                <div class="fact-row">
                                    <span>Browser</span>
                                    <strong>{browser_label or "Unknown"}</strong>
                                </div>
                            </div>
                        </div>
                    ) if show_debug else None}
                </div>
            ) if (session and session.state != "shared" and session.state != "declined" and session.state != "superseded") else None}

            {(
                <div class="phone-state">
                    <div class="panel-head">
                        <div>
                            <h1>Phone connected</h1>
                            <p class="hero-text">
                                This phone is live in the session. You can chat here or head back to the laptop.
                            </p>
                        </div>
                        <span class={state_class(session.state)}>{compact_state_label(session.state)}</span>
                    </div>
                    <div class="phone-summary-grid">
                        <div class="phone-summary-card">
                            <span>Phone label</span>
                            <strong>{session.phone_label or phone_label}</strong>
                        </div>
                        <div class="phone-summary-card">
                            <span>Laptop</span>
                            <strong>{session.host_label}</strong>
                        </div>
                        <div class="phone-summary-card">
                            <span>Session chat</span>
                            <strong>{str(session.phone_message_count) + " messages" if session.phone_message_count > 0 else "Ready to start"}</strong>
                        </div>
                    </div>
                    <div class="chat-shell chat-shell--session">
                        <div class="chat-log">
                            {[
                                <article class={"chat-message chat-message--" + message.role}>
                                    <p class="chat-message__meta">
                                        {(message.client_label or message.role) + " · " + pretty_stamp(message.created_at)}
                                    </p>
                                    <p class="chat-message__body">{message.content}</p>
                                </article> for message in messages
                            ]}
                            {(
                                <p class="inline-note">This session chat is empty. Send the first phone message.</p>
                            ) if (not chat_loading and len(messages) == 0) else None}
                            {(
                                <p class="inline-note">Loading the current phone chat.</p>
                            ) if chat_loading else None}
                        </div>
                        <label class="field">
                            <span class="field__label">Ask this session</span>
                            <textarea
                                class="text-input text-area"
                                value={chat_input}
                                onChange={lambda (e: any) { chat_input = e.target.value; }}
                                placeholder="Ask for a check in, a task, or the next step."
                            />
                        </label>
                        <div class="mobile-actions">
                            <button class="primary-btn" onClick={send_chat} disabled={sending_chat or chat_loading}>
                                {"Sending..." if sending_chat else "Send message"}
                            </button>
                            <button class="ghost-btn" onClick={refresh_messages} disabled={sending_chat}>
                                Refresh chat
                            </button>
                        </div>
                    </div>
                    <div class="mobile-actions">
                        <button class="ghost-btn" onClick={refresh}>Refresh status</button>
                    </div>
                    <button class="ghost-btn debug-toggle" onClick={lambda () { show_debug = not show_debug; }}>
                        {"Show details" if not show_debug else "Hide details"}
                    </button>
                    {(
                        <div class="debug-panel">
                            <div class="facts-list facts-list--stacked">
                                <div class="fact-row">
                                    <span>Joined</span>
                                    <strong>{pretty_stamp(session.approved_at)}</strong>
                                </div>
                                <div class="fact-row">
                                    <span>Browser</span>
                                    <strong>{session.browser_label or browser_label or "Unknown"}</strong>
                                </div>
                            </div>
                        </div>
                    ) if show_debug else None}
                </div>
            ) if (session and session.state == "shared") else None}

            {(
                <div class="phone-state">
                    <div class="panel-head">
                        <div>
                            <h1>This session is closed</h1>
                            <p class="hero-text">
                                This code is no longer active. Open the latest code from the laptop.
                            </p>
                        </div>
                        <span class={state_class(session.state)}>{compact_state_label(session.state)}</span>
                    </div>
                    <div class="chat-shell chat-shell--session">
                        <div class="chat-log">
                            <article class="chat-message chat-message--assistant">
                                <p class="chat-message__meta">Jacuzzi</p>
                                <p class="chat-message__body">
                                    This code is no longer active. Open the latest live code from {session.host_label}.
                                </p>
                            </article>
                            <article class="chat-message chat-message--system">
                                <p class="chat-message__meta">Session state</p>
                                <p class="chat-message__body">{state_label(session.state)}</p>
                            </article>
                        </div>
                        <div class="mobile-actions">
                            <button class="ghost-btn" onClick={refresh}>Refresh status</button>
                        </div>
                    </div>
                    <button class="ghost-btn debug-toggle" onClick={lambda () { show_debug = not show_debug; }}>
                        {"Show details" if not show_debug else "Hide details"}
                    </button>
                    {(
                        <div class="debug-panel">
                            <div class="facts-list facts-list--stacked">
                                <div class="fact-row">
                                    <span>Last update</span>
                                    <strong>{pretty_stamp(session.updated_at)}</strong>
                                </div>
                                <div class="fact-row">
                                    <span>State</span>
                                    <strong>{state_label(session.state)}</strong>
                                </div>
                            </div>
                        </div>
                    ) if show_debug else None}
                </div>
            ) if (session and (session.state == "declined" or session.state == "superseded")) else None}

            {notice and <p class="inline-note">{notice}</p>}
        </section>
    </main>;
}


def:pub app() -> any {
    token = token_from_path(window.location.pathname);
    return <div class="page-root">
        {<PairPage token={token} /> if token else <Dashboard />}
    </div>;
}
