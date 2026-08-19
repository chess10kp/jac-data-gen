"""_normalize_rel: chained call expanded into named steps."""

def _normalize_rel(rel: str) -> str {
    without_leading = rel.lstrip("/");
    return without_leading.replace("\\", "/");
}

with entry {
    cases = ["/a/b.jac", "//x.py", "win\\path\\file.py", "no/change.css", "\\\\a\\b", ""];
    for c in cases {
        print(c + " -> " + _normalize_rel(c));
    }
}
