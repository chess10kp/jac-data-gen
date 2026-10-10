"""Password policy checks."""

def check_password(pw: str, username: str = "") -> list[str] {
    issues: list[str] = [];
    if len(pw) < 12 {
        issues.append("too_short");
    }
    if not any([c.isupper() for c in pw]) {
        issues.append("no_upper");
    }
    if not any([c.islower() for c in pw]) {
        issues.append("no_lower");
    }
    if not any([c.isdigit() for c in pw]) {
        issues.append("no_digit");
    }
    if not any([not c.isalnum() for c in pw]) {
        issues.append("no_symbol");
    }
    if len(username) >= 3 and username.lower() in pw.lower() {
        issues.append("contains_username");
    }
    for i in range(len(pw) - 2) {
        if pw[i] == pw[i + 1] and pw[i] == pw[i + 2] {
            issues.append("repeated_chars");
            break;
        }
    }
    return issues;
}

def strength(pw: str) -> str {
    n = len(check_password(pw));
    if n == 0 {
        return "strong";
    }
    return "fair" if n <= 2 else "weak";
}
