"""RL driver (pure-lib): analytics.narrate (signature-plural phrasing).

Origin: this_is_jac/analytics.jac (the plural-suffix logic from `narrate`,
isolated from the os/time/SSE machinery). Deterministic: builds the
'N signature(s)' fragment, pluralizing the noun unless the count is exactly 1.
The marked body is the unit the policy must regenerate; the `with entry` block
exercises it on fixed inputs and prints a deterministic projection.
"""

def _signature_phrase(signatures: int) -> str {
    plural = "s" if signatures != 1 else "";
    return f"{signatures} signature{plural}";
}

with entry {
    for n in [0, 1, 2, 5, -1] {
        print(_signature_phrase(n));
    }
}
