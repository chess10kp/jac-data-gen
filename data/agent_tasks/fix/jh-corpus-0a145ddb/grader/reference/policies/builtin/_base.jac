"""
Vouch base types. Imported by all policy walkers.
DO NOT add `by llm()` to this file or any file that imports it.
All walkers are deterministic.
"""

import from jaclang.plugin.feature { * }

enum Verdict {
    PASS,
    BLOCK,
    CONFIRM
}

enum BlockReason {
    DESTRUCTIVE_ACTION,
    AUTO_SEND,
    EXTERNAL_WRITE,
    SCOPE_VIOLATION,
    LOW_CONFIDENCE,
    RATE_EXCEEDED,
    UNKNOWN_ACTION,
    CUSTOM
}

obj PolicyResult {
    has verdict: Verdict;
    has block_reason: BlockReason | None = None;
    has message: str = "";
    has policy_name: str = "";
    has requires_confirmation: bool = False;
}

# Helper: build a PASS result
def pass_result(policy_name: str) -> PolicyResult {
    return PolicyResult(
        verdict=Verdict.PASS,
        policy_name=policy_name
    );
}

# Helper: build a BLOCK result
def block_result(
    policy_name: str,
    reason: BlockReason,
    message: str
) -> PolicyResult {
    return PolicyResult(
        verdict=Verdict.BLOCK,
        block_reason=reason,
        message=message,
        policy_name=policy_name,
        requires_confirmation=False
    );
}

# Helper: build a CONFIRM result
def confirm_result(
    policy_name: str,
    message: str
) -> PolicyResult {
    return PolicyResult(
        verdict=Verdict.CONFIRM,
        policy_name=policy_name,
        message=message,
        requires_confirmation=True
    );
}
