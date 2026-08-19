import os;

glob _LANG: dict[str, str] = {
    "jac": "Jac", "py": "Python", "css": "CSS", "toml": "TOML",
    "md": "Markdown", "json": "JSON", "svg": "SVG", "sh": "Shell",
    "ts": "TypeScript", "tsx": "TSX", "js": "JavaScript", "jsx": "JSX",
    "zig": "Zig", "html": "HTML", "txt": "Text", "yml": "YAML", "yaml": "YAML"
};

def _lang_label(rel: str) -> str {
    if rel.endswith(".jac") {
        return "Jac";
    }
    ext = rel.rsplit(".", 1)[-1].lower() if "." in os.path.basename(rel) else "";
    return _LANG.get(ext, ext.upper() or "Text");
}

def _file_meta(rel: str, size: int) -> dict {
    return {
        "path": rel,
        "name": os.path.basename(rel),
        "dir": os.path.dirname(rel),
        "lang": _lang_label(rel),
        "size": size
    };
}

with entry {
    cases = [("src/main.jac", 1234), ("a/b/style.css", 88), ("README", 12), ("x.py", 5)];
    for (rel, sz) in cases {
        m = _file_meta(rel, sz);
        print(str(m["path"]) + "|" + str(m["name"]) + "|" + str(m["dir"]) + "|" + str(m["lang"]) + "|" + str(m["size"]));
    }
}
