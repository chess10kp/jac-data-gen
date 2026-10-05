"""
Vouch v2: Undo Integrity Guard
Checks whether an action can actually be undone before executing.
Classifies undo capability as REVERSIBLE, BEST_EFFORT, or IRREVERSIBLE.
"""

import from ._base { pass_result, confirm_result }

enum UndoCapability {
    REVERSIBLE,    # Undo will definitely work
    BEST_EFFORT,   # Undo may partially work
    IRREVERSIBLE   # No undo possible
}

# Actions that are definitely irreversible
glob IRREVERSIBLE_ACTIONS: list[str] = [
    "send_email", "send_sms", "send_message",
    "post_tweet", "publish_post", "post_to_linkedin",
    "make_payment", "transfer_funds", "charge_card",
    "delete_account", "deactivate_account",
    "notify_user", "send_notification",
    "submit_form", "place_order"
];

# Actions that can be partially undone
glob BEST_EFFORT_ACTIONS: list[str] = [
    "create_calendar_event",  # can delete but attendees already notified
    "share_document",         # can unshare but user may have seen it
    "invite_user",            # can revoke but notification sent
    "update_record",          # can revert but version history shows edit
    "publish_article",        # can unpublish but may be cached/indexed
    "grant_access"            # can revoke but user may have accessed
];

walker CheckUndoIntegrity {
    has action_type: str;
    has has_undo_fn: bool = False;

    can check with entry {
        action_lower = self.action_type.lower().strip();

        # No undo function provided
        if not self.has_undo_fn {
            # Check if action is in irreversible list
            for action in IRREVERSIBLE_ACTIONS {
                if action_lower.startswith(action) {
                    report confirm_result(
                        "undo_integrity",
                        f"Action '{self.action_type}' is IRREVERSIBLE and no undo function was provided. Once executed, this cannot be reversed."
                    );
                    disengage;
                }
            }
            report pass_result("undo_integrity");
            disengage;
        }

        # Has undo function -- check capability level
        for action in IRREVERSIBLE_ACTIONS {
            if action_lower.startswith(action) {
                report confirm_result(
                    "undo_integrity",
                    f"Action '{self.action_type}' has an undo function but the action is IRREVERSIBLE (e.g., email already delivered). Undo may not fully reverse the action."
                );
                disengage;
            }
        }

        for action in BEST_EFFORT_ACTIONS {
            if action_lower.startswith(action) {
                report pass_result("undo_integrity");
                disengage;
            }
        }

        # Action not in any list -- assume reversible if undo fn exists
        report pass_result("undo_integrity");
    }
}
