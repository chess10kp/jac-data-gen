"""RL driver (pure-lib): guestbook.sign_guestbook.sign (name normalization).

Origin: this_is_jac/guestbook.jac (the visitor-name normalization expression
inside the `sign` ability, isolated from the graph machinery). Deterministic:
strips surrounding whitespace, caps the name at 40 characters, and falls back to
'anonymous' when the result is empty. The marked body is the unit the policy
must regenerate; the `with entry` block exercises it on fixed inputs and prints
a deterministic projection.
"""

def _norm_name(name: str) -> str {
    return name.strip()[:40] or "anonymous";
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
