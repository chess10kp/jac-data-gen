"""LegalForge AI -- Jac-native auth + RBAC helpers."""

glob DEMO_USERS = {
    "admin": {"password": "admin123", "role": "admin", "name": "Sarah Chen, Esq."},
    "analyst": {"password": "analyst123", "role": "analyst", "name": "James Wong"},
    "viewer": {"password": "viewer123", "role": "viewer", "name": "Demo Viewer"}
};

glob ROLE_PERMISSIONS = {
    "admin": ["read", "analyze", "negotiate", "export", "view_audit"],
    "analyst": ["read", "analyze", "negotiate", "export", "view_audit"],
    "viewer": ["read"]
};


def authenticate_user(username: str, password: str) -> dict {
    user = DEMO_USERS.get(username, {});
    if not user or user.get("password", "") != password {
        return {"authenticated": False, "error": "Invalid credentials"};
    }
    role = user.get("role", "viewer");
    token = f"{username}|{role}";
    return {
        "authenticated": True,
        "token": token,
        "role": role,
        "name": user.get("name", username)
    };
}


def verify_token(token: str) -> dict {
    if not token {
        return {"valid": False, "error": "Missing token"};
    }
    parts = token.split("|");
    if len(parts) != 2 {
        return {"valid": False, "error": "Malformed token"};
    }
    username = parts[0];
    role = parts[1];
    user = DEMO_USERS.get(username, {});
    if not user {
        return {"valid": False, "error": "Unknown user"};
    }
    if user.get("role", "") != role {
        return {"valid": False, "error": "Role mismatch"};
    }
    return {"valid": True, "sub": username, "role": role, "name": user.get("name", username)};
}


def check_permission(role: str, action: str) -> bool {
    allowed = ROLE_PERMISSIONS.get(role, []);
    return action in allowed;
}


walker AuthGateWalker {
    has token: str = "";
    has requested_action: str = "";
    has user_role: str = "";

    can validate with Root entry {
        role = self.user_role;
        if self.token {
            tok = verify_token(self.token);
            if not tok.get("valid", False) {
                report {"authorized": False, "reason": tok.get("error", "Invalid token")};
                disengage;
            }
            role = tok.get("role", role);
        }
        if not check_permission(role, self.requested_action) {
            report {"authorized": False, "reason": "Insufficient permissions"};
            disengage;
        }
        report {"authorized": True, "role": role};
    }
}
