"""RL driver (pure-lib): analytics.narrate (signature-plural phrasing).

Origin: this_is_jac/analytics.jac (the plural-suffix logic from `narrate`,
isolated from the os/time/SSE machinery). Deterministic: builds the
'N signature(s)' fragment, pluralizing the noun unless the count is exactly 1.
The marked body is the unit the policy must regenerate; the `with entry` block
exercises it on fixed inputs and prints a deterministic projection.
"""

def _signature_phrase(signatures: int) -> str {
    # >>>HOLE id="lib_narrate_plural" instruction="Implement _signature_phrase(signatures): return the string formed by the count, a space, the word 'signature', and a plural suffix; the suffix is 's' unless signatures equals exactly 1, in which case it is the empty string."
    plural = "s" if signatures != 1 else "";
    return f"{signatures} signature{plural}";
    # <<<HOLE
}

with entry {
    for n in [0, 1, 2, 5, -1] {
        print(_signature_phrase(n));
    }
}
