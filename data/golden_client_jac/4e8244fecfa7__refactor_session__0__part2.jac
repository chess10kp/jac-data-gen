"""_blank: defaults centralized in a BlankPayload obj with a to_dict() projection."""

obj BlankPayload {
    has path: str,
        error: str,
        lang: str = "",
        html: str = "",
        lines: int = 0,
        raw: str = "",
        truncated: bool = False;

    def to_dict() -> dict;
}

impl BlankPayload.to_dict {
    return {
        "path": self.path, "lang": self.lang, "html": self.html,
        "lines": self.lines, "raw": self.raw, "truncated": self.truncated,
        "error": self.error
    };
}

def _blank(rel: str, err: str) -> dict {
    return BlankPayload(path=rel, error=err).to_dict();
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
