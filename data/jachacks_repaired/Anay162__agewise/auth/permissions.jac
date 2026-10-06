"""Permission checks for AgeWise operations."""

import from auth.roles { ROLES, ROLE_HIERARCHY }

# Permission action constants
glob PERM_VIEW_CLAIMS: str = "view_claims";
glob PERM_VIEW_DISPUTES: str = "view_disputes";
glob PERM_CREATE_DISPUTE: str = "create_dispute";
glob PERM_SUBMIT_APPEAL: str = "submit_appeal";
glob PERM_VIEW_FINANCIAL: str = "view_financial";
glob PERM_VIEW_LEGAL: str = "view_legal";
glob PERM_INITIATE_CALL: str = "initiate_call";
glob PERM_VIEW_NOTIFICATIONS: str = "view_notifications";
glob PERM_MANAGE_USERS: str = "manage_users";
glob PERM_EXPORT_DATA: str = "export_data";

"""Check if a role has permission to perform an action."""
def has_permission(role: str, action: str) -> bool {
    if role == "ADMIN" {
        return True;
    }
    role_config = ROLES.get(role, {});
    if role_config.get("all_permissions", False) {
        return True;
    }
    # Map actions to role fields
    action_map = {
        PERM_VIEW_CLAIMS: "can_view_own_data",
        PERM_VIEW_DISPUTES: "can_view_own_data",
        PERM_CREATE_DISPUTE: "can_view_own_data",
        PERM_SUBMIT_APPEAL: "can_approve_appeals",
        PERM_VIEW_FINANCIAL: "can_view_financial",
        PERM_VIEW_LEGAL: "can_view_legal",
        PERM_INITIATE_CALL: "can_initiate_calls",
        PERM_VIEW_NOTIFICATIONS: "can_view_own_data",
        PERM_MANAGE_USERS: "all_permissions",
        PERM_EXPORT_DATA: "can_approve_appeals"
    };
    field = action_map.get(action, "");
    if field == "" {
        return False;
    }
    return role_config.get(field, False);
}

"""Raise ValueError if role lacks permission."""
def require_permission(role: str, action: str) -> None {
    if not has_permission(role, action) {
        raise ValueError(f"Role '{role}' does not have permission '{action}'");
    }
}
