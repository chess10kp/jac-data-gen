"""Session management for AgeWise user sessions."""

import from datetime { datetime, timedelta }
import from uuid { uuid4 }

# Session store (in production, use Redis or DB)
glob _sessions: dict = {};

# Session timeout in minutes
glob SESSION_TIMEOUT_MINUTES: int = 30;
glob EXTENDED_TIMEOUT_MINUTES: int = 480;  # 8 hours for caregivers

"""Create a new session and return the session token."""
def create_session(user_id: str, role: str, patient_id: str, extended: bool = False) -> str {
    token = str(uuid4());
    timeout = EXTENDED_TIMEOUT_MINUTES if extended else SESSION_TIMEOUT_MINUTES;
    _sessions[token] = {
        "user_id": user_id,
        "role": role,
        "patient_id": patient_id,
        "created_at": datetime.utcnow().isoformat(),
        "expires_at": (datetime.utcnow() + timedelta(minutes=timeout)).isoformat(),
        "last_activity": datetime.utcnow().isoformat()
    };
    return token;
}

"""Validate a session token and return session data or empty dict."""
def validate_session(token: str) -> dict {
    session = _sessions.get(token, {});
    if not session {
        return {};
    }
    expiry = datetime.fromisoformat(session["expires_at"]);
    if datetime.utcnow() > expiry {
        del _sessions[token];
        return {};
    }
    # Refresh last activity
    session["last_activity"] = datetime.utcnow().isoformat();
    return session;
}

"""Invalidate (logout) a session."""
def invalidate_session(token: str) -> None {
    if token in _sessions {
        del _sessions[token];
    }
}

"""Return all active sessions for a user."""
def get_active_sessions(user_id: str) -> list[dict] {
    now = datetime.utcnow();
    return [
        s for s in _sessions.values()
        if s["user_id"] == user_id and datetime.fromisoformat(s["expires_at"]) > now
    ];
}

"""Invalidate all sessions for a user. Returns count removed."""
def invalidate_all_sessions(user_id: str) -> int {
    tokens_to_remove = [t for (t, s) in _sessions.items() if s["user_id"] == user_id];
    for t in tokens_to_remove {
        del _sessions[t];
    }
    return len(tokens_to_remove);
}
