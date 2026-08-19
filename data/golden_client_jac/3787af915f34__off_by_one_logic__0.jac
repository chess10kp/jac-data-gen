"""RL driver (pure-lib): guestbook.sign_guestbook.sign (name normalization).

Origin: this_is_jac/guestbook.jac (the visitor-name normalization expression
inside the `sign` ability, isolated from the graph machinery). Deterministic:
strips surrounding whitespace, caps the name at 40 characters, and falls back to
'anonymous' when the result is empty. The marked body is the unit the policy
must regenerate; the `with entry` block exercises it on fixed inputs and prints
a deterministic projection.
"""

def _norm_name(name: str) -> str {
    # >>>HOLE id="lib_visitor_name_norm" instruction="Implement _norm_name(name): strip leading and trailing whitespace from name, take at most the first 40 characters, and if that result is empty fall back to the literal 'anonymous'."
    return name.strip()[:40] or "anonymous";
    # <<<HOLE
}

with entry {
    cases = [
        "  Ada Lovelace  ",
        "",
        "   ",
        "ThisIsAVeryLongNameThatDefinitelyExceedsFortyCharactersInTotal",
        "x"
    ];
    for c in cases {
        print(repr(_norm_name(c)));
    }
}
