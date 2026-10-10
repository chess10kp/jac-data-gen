"""
Vouch v2: Context Poisoning Detector
Scans memory retrieval results for poisoning signatures before
they enter LLM context. Catches persistent injection attacks
that standard scanners miss because they only scan current input.
"""

import from vouch.policies.builtin._base { * }

# Poisoning signatures in stored memory chunks
glob POISONING_PATTERNS: list[str] = [
    "ignore previous instructions",
    "override all rules",
    "you must always",
    "from now on always",
    "your new primary directive",
    "secret instruction:",
    "hidden instruction:",
    "when asked about",
    "never reveal",
    "always respond with",
    "pretend that",
    "act as though",
    "the real answer is",
    "disregard safety",
    "bypass all",
    "system override"
];

# Authority claim patterns (someone stored "I am the admin")
glob AUTHORITY_CLAIMS: list[str] = [
    "i am the administrator",
    "i am the owner",
    "admin access granted",
    "elevated privileges",
    "full access mode",
    "authorized override",
    "master key:",
    "root access"
];

walker CheckMemoryChunk {
    has chunk_content: str;
    has chunk_id: str = "";
    has retrieval_query: str = "";

    can check with entry {
        content_lower = self.chunk_content.lower().strip();

        # Check poisoning patterns
        for pattern in POISONING_PATTERNS {
            if pattern in content_lower {
                report block_result(
                    "context_poisoning",
                    BlockReason.CUSTOM,
                    f"Memory poisoning detected in chunk '{self.chunk_id}': pattern '{pattern}'. Retrieved by query: '{self.retrieval_query}'"
                );
                disengage;
            }
        }

        # Check authority claims
        for pattern in AUTHORITY_CLAIMS {
            if pattern in content_lower {
                report confirm_result(
                    "context_poisoning",
                    f"Suspicious authority claim in memory chunk '{self.chunk_id}': '{pattern}'. Review before using in context."
                );
                disengage;
            }
        }

        report pass_result("context_poisoning");
    }
}
