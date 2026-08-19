glob LANG_TABLE: dict = {"py": "Python", "css": "CSS", "toml": "TOML", "md": "Markdown",
                         "json": "JSON", "sh": "Shell", "ts": "TypeScript",
                         "js": "JavaScript", "html": "HTML", "txt": "Text",
                         "yml": "YAML", "yaml": "YAML"};

def lang_label(rel: str) -> str {
    if rel.endswith(".jac") {
        return "Jac";
    }
    base = rel.rsplit("/", 1)[-1];
    ext = base.rsplit(".", 1)[-1].lower() if "." in base else "";
    return LANG_TABLE.get(ext, ext.upper() or "Text");
}

with entry {
    print(lang_label('ui/app.jac'));
}
