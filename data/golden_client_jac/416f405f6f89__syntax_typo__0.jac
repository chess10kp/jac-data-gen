"""RL driver (pure-lib): source_index.list_files (per-file metadata record).

Origin: this_is_jac/source_index.jac (the metadata dict built per file inside
`list_files`, with its `_lang_label`/`_LANG` dependency inlined verbatim and the
size passed in instead of read from disk). Deterministic: from a repo-relative
path and a size, builds the {path, name, dir, lang, size} record the source
browser hands back. The marked body is the unit the policy must regenerate; the
`with entry` block exercises it on fixed inputs and prints a deterministic
projection.
"""

import os;

glob _LANG: dict = {
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
    # >>>HOLE id="lib_list_file_meta" instruction="Implement _file_meta(rel, size): return a dict with key 'path' set to rel, key 'name' set to the basename of rel (its component after the last slash, via os.path.basename), key 'dir' set to the directory part of rel (via os.path.dirname), key 'lang' set to _lang_label(rel), and key 'size' set to size."
    return {
        "path": rel,
        "name": os.path.basename(rel),
        "dir": os.path.dirname(rel),
        "lang": _lang_label(rel),
        "size": size
    };
    # <<<HOLE
}

with entry {
    cases = [("src/main.jac", 1234), ("a/b/style.css", 88), ("README", 12), ("x.py", 5)];
    for (rel, sz) in cases {
        m = _file_meta(rel, sz);
        print(m["path"] + "|" + m["name"] + "|" + m["dir"] + "|" + m["lang"] + "|" + str(m["size"]));
    }
}
