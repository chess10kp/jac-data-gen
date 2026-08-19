"""Normalize a guestbook name: strip, cap at 40 chars, fall back to 'anonymous' when empty."""

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
