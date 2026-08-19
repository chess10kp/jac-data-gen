def file_meta(spec: dict) -> dict {
    rel = spec["path"];
    langs = {"jac": "Jac", "py": "Python", "md": "Markdown", "json": "JSON", "toml": "TOML"};
    name = rel.rsplit("/", 1)[-1] if "/" in rel else rel;
    folder = rel.rsplit("/", 1)[0] if "/" in rel else "";
    ext = name.rsplit(".", 1)[-1].lower() if "." in name else "";
    return {"path": rel, "name": name, "dir": folder,
            "lang": langs.get(ext, ext.upper() or "Text"), "size": spec["size"]};
}

with entry {
    print(file_meta({'path': 'client/pages/feed.jac', 'size': 2048}));
}
