"""RL driver (pure-lib): source_index.get_file (path normalization).

Origin: this_is_jac/source_index.jac (the leading-slash + backslash
normalization performed at the top of `get_file`). Deterministic: strips any
leading forward slashes and converts backslashes to forward slashes. The marked
body is the unit the policy must regenerate; the `with entry` block exercises it
on fixed inputs and prints a deterministic projection.
"""

def _normalize_rel(rel: str) -> str {
    return rel.lstrip("/").replace("\\", "/");
}

with entry {
    cases = ["/a/b.jac", "//x.py", "win\\path\\file.py", "no/change.css", "\\\\a\\b", ""];
    for c in cases {
        print(c + " -> " + _normalize_rel(c));
    }
}
