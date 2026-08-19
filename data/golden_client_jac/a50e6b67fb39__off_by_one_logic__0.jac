"""RL driver (pure-lib): guestbook.sign_guestbook.sign (message normalization).

Origin: this_is_jac/guestbook.jac (the visitor-message normalization expression
inside the `sign` ability, isolated from the graph machinery). Deterministic:
strips surrounding whitespace and caps the message at 200 characters. The marked
body is the unit the policy must regenerate; the `with entry` block exercises it
on fixed inputs and prints a deterministic projection.
"""

def _norm_message(message: str) -> str {
    # >>>HOLE id="lib_visitor_message_norm" instruction="Implement _norm_message(message): strip leading and trailing whitespace from message and return at most its first 200 characters."
    return message.strip()[:200];
    # <<<HOLE
}

with entry {
    long = "a" * 250;
    cases = ["  hello world  ", "", "   trimmed   ", long];
    for c in cases {
        r = _norm_message(c);
        print(str(len(r)) + "|" + repr(r));
    }
}
