"""Normalize a guestbook message: strip surrounding whitespace and cap at 200 characters."""

def _norm_message(message: str) -> str {
    return message.strip()[:200];
}

with entry {
    long = "a" * 250;
    cases = ["  hello world  ", "", "   trimmed   ", long];
    for c in cases {
        r = _norm_message(c);
        print(str(len(r)) + "|" + repr(r));
    }
}
