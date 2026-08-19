obj FilePayload {
    has path: str = "";
    has lang: str = "";
    has html: str = "";
    has lines: int = 0;
    has raw: str = "";
    has truncated: bool = False;
    has error: str = "";

    def render -> dict {
        return {"path": self.path, "lang": self.lang, "html": self.html,
                "lines": self.lines, "raw": self.raw,
                "truncated": self.truncated, "error": self.error};
    }
}

def blank_payload(spec: dict) -> dict {
    return FilePayload(path=spec["path"], error=spec["error"]).render();
}

with entry {
    print(blank_payload({'path': 'src/app.jac', 'error': 'not found'}));
}
