"""_lang_label: declaration separated from its impl body."""

import os;

glob _LANG: dict = {
    "jac": "Jac", "py": "Python", "css": "CSS", "toml": "TOML",
    "md": "Markdown", "json": "JSON", "svg": "SVG", "sh": "Shell",
    "ts": "TypeScript", "tsx": "TSX", "js": "JavaScript", "jsx": "JSX",
    "zig": "Zig", "html": "HTML", "txt": "Text", "yml": "YAML", "yaml": "YAML"
};

def _lang_label(rel: str) -> str;

impl _lang_label {
    if rel.endswith(".jac") {
        return "Jac";
    }
    ext = rel.rsplit(".", 1)[-1].lower() if "." in os.path.basename(rel) else "";
    return str(_LANG.get(ext, ext.upper() or "Text"));
}

with entry {
    cases = ["a/b/main.jac", "x.py", "style.css", "deep/nested.TS", "README", "data.unknown", "Makefile.toml"];
    for c in cases {
        print(c + " -> " + _lang_label(c));
    }
}
