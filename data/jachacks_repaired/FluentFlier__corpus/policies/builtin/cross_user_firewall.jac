"""
Vouch v2: Cross-User Context Firewall
Enforces user context isolation. Checks that no content from
other users bleeds into the current user's LLM context.
"""

import from ._base { BlockReason, pass_result, block_result, confirm_result }

walker CheckContextIsolation {
    has current_user_id: str;
    has context_user_ids: list[str] = [];  # user IDs found in the context window
    has memory_namespaces: list[str] = []; # namespaces of retrieved memory chunks

    can check with entry {
        # Check for foreign user IDs in context
        foreign_users = [uid for uid in self.context_user_ids if uid != self.current_user_id];
        if foreign_users {
            report block_result(
                "cross_user_firewall",
                BlockReason.CUSTOM,
                f"Cross-user contamination detected: context contains data from user(s) {foreign_users}. Current user: {self.current_user_id}"
            );
            disengage;
        }

        # Check memory namespace isolation
        expected_ns = self.current_user_id.lower();
        foreign_ns = [ns for ns in self.memory_namespaces if expected_ns not in ns.lower()];
        if foreign_ns {
            report confirm_result(
                "cross_user_firewall",
                f"Memory chunks from non-user namespaces detected: {foreign_ns}. Expected namespace containing: '{expected_ns}'"
            );
            disengage;
        }

        report pass_result("cross_user_firewall");
    }
}
