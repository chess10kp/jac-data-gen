def should_skip(rel: str) -> bool {
    if "__pycache__" in rel {
        return True;
    }
    base = rel.rsplit("/", 1)[-1];
    if base.startswith(".") {
        return True;
    }
    ext = ("." + base.rsplit(".", 1)[-1].lower()) if "." in base else "";
    return ext in {".png", ".jpg", ".gif", ".woff", ".zip", ".pdf", ".pyc", ".so"};
}

with entry {
    print(should_skip('app/__pycache__/m.pyc'));
}
