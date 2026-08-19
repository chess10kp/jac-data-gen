obj BlankPayload {
    has path: str, error: str,
        lang: str = "", html: str = "", lines: int = 0,
        raw: str = "", truncated: bool = False;

    def to_dict() -> dict;
}

impl BlankPayload.to_dict {
    return {
        "path": self.path, "lang": self.lang, "html": self.html,
        "lines": self.lines, "raw": self.raw, "truncated": self.truncated
    };
}

def _blank(rel: str, err: str) -> dict {
    return BlankPayload(path=rel, error=err).to_dict();
}
