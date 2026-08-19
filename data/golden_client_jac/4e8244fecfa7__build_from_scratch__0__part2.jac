def _blank(rel: str, err: str) -> dict {
    return {
        "path": rel, "lang": "", "html": "", "lines": 0,
        "raw": "", "truncated": False, "error": err
    };
}

with entry {
    cases = [
        ("a/b.jac", "File not found."),
        ("", "Invalid path."),
        ("x.py", "Could not read file.")
    ];
    for (rel, err) in cases {
        d = _blank(rel, err);
        print(str(d["path"]) + "|" + str(d["error"]) + "|" + str(d["lang"]) + "|" + str(d["lines"]) + "|" + str(d["truncated"]));
    }
}
