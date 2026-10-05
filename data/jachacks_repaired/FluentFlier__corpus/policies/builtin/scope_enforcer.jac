"""
Vouch v2: Action Scope Enforcer
Enforces per-integration, per-action scope at runtime.
Checks if a proposed action on a specific integration
is within the developer's declared scope.
"""

import from ._base { BlockReason, pass_result, block_result }

walker CheckActionScope {
    has integration: str;
    has action: str;
    has scope_map: dict = {};  # {"google_calendar": ["create_event", "read_events"], ...}

    can check with entry {
        integration_lower = self.integration.lower().strip();
        action_lower = self.action.lower().strip();

        # If no scope map is declared, pass everything
        if not self.scope_map {
            report pass_result("scope_enforcer");
            disengage;
        }

        # Check if integration exists in scope map
        if integration_lower not in self.scope_map {
            report block_result(
                "scope_enforcer",
                BlockReason.SCOPE_VIOLATION,
                f"Integration '{self.integration}' is not in the allowed scope. Allowed integrations: {list(self.scope_map.keys())}"
            );
            disengage;
        }

        # Check if action is allowed for this integration
        allowed_actions = [a.lower() for a in self.scope_map[integration_lower]];
        if action_lower not in allowed_actions {
            report block_result(
                "scope_enforcer",
                BlockReason.SCOPE_VIOLATION,
                f"Action '{self.action}' is not allowed on integration '{self.integration}'. Allowed: {self.scope_map[integration_lower]}"
            );
            disengage;
        }

        report pass_result("scope_enforcer");
    }
}
