def _normalize_rel(rel: str) -> str {
    return rel.lstrip("/").replace("\\", "/");
}

with entry {
    cases = ["/a/b.jac", "//x.py", "win\\path\\file.py", "no/change.css", "\\\\a\\b", ""];
    for c in cases {
        print(c + " -> " + _normalize_rel(c));
    }
}
