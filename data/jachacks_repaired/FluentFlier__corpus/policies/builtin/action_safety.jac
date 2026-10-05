"""
Vouch built-in: Action Safety
Hard-coded safety rules that apply universally.
These cannot be disabled or overridden by developer config.

A developer can ADD rules via their policy file.
They cannot REMOVE these built-in rules.
"""

import from ._base { BlockReason, pass_result, block_result, confirm_result }

# Actions that are ALWAYS blocked.
# The agent must never auto-execute any of these.
glob ALWAYS_BLOCK_PREFIXES: list[str] = [
    # File system destruction
    "delete_file",       "remove_file",       "unlink_file",
    "bulk_delete",       "purge_files",       "wipe_directory",
    # Database destruction
    "drop_table",        "truncate_table",    "delete_database",
    "purge_records",     "bulk_delete_rows",
    # Account/access destruction
    "deactivate_account", "delete_account",   "revoke_access",
    "remove_user",       "ban_user",
    # Financial
    "make_payment",      "transfer_funds",    "charge_card",
    "process_refund",    "cancel_subscription"
];

# Actions that ALWAYS require user confirmation.
# Pass user_approved=true to bypass (only after user has seen and confirmed).
glob ALWAYS_CONFIRM_PREFIXES: list[str] = [
    # Communication: messages the user hasn't reviewed
    "send_email",        "send_message",      "send_sms",
    "send_notification", "reply_to_email",
    # Publishing
    "post_tweet",        "publish_post",      "post_to_linkedin",
    "publish_article",   "submit_form",
    # Scheduling
    "create_calendar_event", "book_meeting",  "schedule_appointment",
    # Sharing and permissions
    "share_document",    "invite_user",       "grant_access",
    "make_public",       "change_permissions",
    # Data export
    "export_data",       "download_all",      "send_report"
];

walker CheckActionSafety {
    has action_type: str;
    has user_approved: bool = False;

    can check with entry {
        action_lower = self.action_type.lower().strip();

        # Check ALWAYS_BLOCK -- no override, no user_approved bypass
        for prefix in ALWAYS_BLOCK_PREFIXES {
            if action_lower.startswith(prefix) {
                report block_result(
                    "action_safety",
                    BlockReason.DESTRUCTIVE_ACTION,
                    f"'{self.action_type}' is a destructive action and cannot be executed automatically."
                );
                disengage;
            }
        }

        # Check ALWAYS_CONFIRM -- bypass only if user_approved=True
        for prefix in ALWAYS_CONFIRM_PREFIXES {
            if action_lower.startswith(prefix) {
                if not self.user_approved {
                    report confirm_result(
                        "action_safety",
                        f"Review before sending: '{self.action_type}' will go to an external recipient."
                    );
                    disengage;
                }
            }
        }

        report pass_result("action_safety");
    }
}
