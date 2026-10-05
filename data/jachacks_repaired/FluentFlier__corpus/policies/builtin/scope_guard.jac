"""
Vouch built-in: Scope Guard
Checks whether the proposed action falls within the developer's declared
agent scope. Scope is opt-in: if no allowed_actions are declared in the
policy file, this walker passes everything.
"""

import from ._base { pass_result, confirm_result }

walker CheckScope {
    has action_type: str;
    has allowed_actions: list[str] = [];
    has intent_context: str = "";

    can check with entry {
        # If developer declared no scope, pass everything
        if not self.allowed_actions {
            report pass_result("scope_guard");
            disengage;
        }

        action_lower = self.action_type.lower().strip();

        # Check if action is within any allowed prefix
        for allowed in self.allowed_actions {
            if action_lower.startswith(allowed.lower()) {
                report pass_result("scope_guard");
                disengage;
            }
        }

        # Action is outside declared scope -- ask user
        context_hint = f" (intent: {self.intent_context})" if self.intent_context else "";
        report confirm_result(
            "scope_guard",
            f"'{self.action_type}' is outside this agent's normal scope{context_hint}. Proceed?"
        );
    }
}
