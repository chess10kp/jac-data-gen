"""
Vouch v2: Prompt Injection Firewall
Scans external content for injection patterns before it touches LLM context.
Returns CLEAN, SUSPICIOUS, or BLOCK with the triggering pattern.

Pattern categories:
  - Instruction override: "ignore previous", "new task", "you are now"
  - Role escalation: "you are an admin", "system prompt", "act as"
  - Data exfiltration: "send to", "forward to", "email to"
  - Encoded payloads: base64, hex, unicode obfuscation
"""

import from ._base { BlockReason, pass_result, block_result, confirm_result }

enum InjectionSeverity {
    CLEAN,
    SUSPICIOUS,
    BLOCK
}

# Instruction override patterns
glob INSTRUCTION_OVERRIDE: list[str] = [
    "ignore previous instructions",
    "ignore all previous",
    "disregard above",
    "forget everything",
    "new task:",
    "new instructions:",
    "you are now",
    "your new role",
    "override:",
    "system:",
    "assistant:",
    "ignore the above",
    "do not follow",
    "stop following",
    "instead of",
    "from now on",
    "reset your instructions",
    "pretend you are",
    "act as if"
];

# Role escalation patterns
glob ROLE_ESCALATION: list[str] = [
    "you are an admin",
    "you are root",
    "you have full access",
    "system prompt",
    "developer mode",
    "sudo mode",
    "unrestricted mode",
    "jailbreak",
    "god mode",
    "bypass safety",
    "bypass filters",
    "no restrictions",
    "without limitations",
    "act as an unrestricted",
    "dan mode"
];

# Data exfiltration patterns
glob EXFILTRATION: list[str] = [
    "send to",
    "forward to",
    "email to",
    "post to",
    "upload to",
    "exfiltrate",
    "send all data",
    "forward all emails",
    "share with",
    "transmit to",
    "copy to external",
    "leak the"
];

walker CheckInjection {
    has content: str;
    has source: str = "unknown";

    can check with entry {
        content_lower = self.content.lower().strip();

        # Check instruction override patterns (BLOCK)
        for pattern in INSTRUCTION_OVERRIDE {
            if pattern in content_lower {
                report block_result(
                    "injection_firewall",
                    BlockReason.CUSTOM,
                    f"Prompt injection detected: instruction override pattern '{pattern}' in content from '{self.source}'"
                );
                disengage;
            }
        }

        # Check role escalation patterns (BLOCK)
        for pattern in ROLE_ESCALATION {
            if pattern in content_lower {
                report block_result(
                    "injection_firewall",
                    BlockReason.CUSTOM,
                    f"Prompt injection detected: role escalation pattern '{pattern}' in content from '{self.source}'"
                );
                disengage;
            }
        }

        # Check exfiltration patterns (CONFIRM)
        for pattern in EXFILTRATION {
            if pattern in content_lower {
                report confirm_result(
                    "injection_firewall",
                    f"Suspicious content: possible data exfiltration pattern '{pattern}' in content from '{self.source}'"
                );
                disengage;
            }
        }

        # Check for encoded content (base64-like patterns)
        # Long sequences of alphanumeric + /+ = are suspicious
        # This is a heuristic, not perfect
        if len(content_lower) > 200 {
            alpha_count = 0;
            for c in content_lower {
                if c.isalnum() or c == '/' or c == '+' or c == '=' {
                    alpha_count += 1;
                }
            }
            ratio = alpha_count / len(content_lower);
            if ratio > 0.95 {
                report confirm_result(
                    "injection_firewall",
                    f"Suspicious content: possible encoded payload detected from '{self.source}' (density: {ratio:.2f})"
                );
                disengage;
            }
        }

        report pass_result("injection_firewall");
    }
}
