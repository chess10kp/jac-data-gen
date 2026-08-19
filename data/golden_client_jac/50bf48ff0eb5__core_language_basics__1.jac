"""RL driver (pure-lib): source_index._lang_label.

Origin: this_is_jac/source_index.jac. Deterministic: maps a file path to its
human language label using the _LANG table. The marked body is the unit the
policy must regenerate; the `with entry` block exercises it and prints a fixed,
deterministic projection (no ids, no timestamps).
"""

import os;

glob _LANG: dict = {
    "jac": "Jac", "py": "Python", "css": "CSS", "toml": "TOML",
    "md": "Markdown", "json": "JSON", "svg": "SVG", "sh": "Shell",
    "ts": "TypeScript", "tsx": "TSX", "js": "JavaScript", "jsx": "JSX",
    "zig": "Zig", "html": "HTML", "txt": "Text", "yml": "YAML", "yaml": "YAML"
};

def _lang_label(rel: str) -> str {
    # >>>HOLE id="lib_lang_label" instruction="Implement _lang_label(rel): return the human language label for a file path. Any path ending in '.jac' is 'Jac'. Otherwise take the lowercased extension after the last dot of the basename (or '' if the basename has no dot) and look it up in the _LANG dict; if missing, return the extension uppercased, or 'Text' when there is no extension."
    if rel.endswith(".jac") {
        return "Jac";
    }
    ext = rel.rsplit(".", 1)[-1].lower() if "." in os.path.basename(rel) else "";
    return _LANG.get(ext, ext.upper() or "Text");
    # <<<HOLE
}

with entry {
    cases = ["a/b/main.jac", "x.py", "style.css", "deep/nested.TS", "README", "data.unknown", "Makefile.toml"];
    for c in cases {
        print(c + " -> " + _lang_label(c));
    }
}
