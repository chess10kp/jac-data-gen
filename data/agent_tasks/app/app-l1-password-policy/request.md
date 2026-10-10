need a password policy checker in jac. file: `passcheck.jac`, plain functions, nothing else.

`check_password(pw: str, username: str = "") -> list[str]` returns the list of rule codes the password breaks, in this order, empty list if it's fine:
- `too_short` — fewer than 12 chars
- `no_upper` — no uppercase letter
- `no_lower` — no lowercase letter
- `no_digit` — no digit
- `no_symbol` — no char that is not a letter or digit
- `contains_username` — username (case-insensitive) appears inside the password; only applies when the username is at least 3 chars
- `repeated_chars` — the same character 3+ times in a row (e.g. "aaa", "111")

`strength(pw: str) -> str` -> "strong" when no violations, "fair" for 1-2, "weak" for 3 or more (no username here).

thanks
