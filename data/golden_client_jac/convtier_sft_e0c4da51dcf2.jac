def is_source(rel: str) -> bool {
    name = rel.rsplit("/", 1)[-1];
    if "__pycache__" in rel or name.startswith(".") {
        return False;
    }
    ext = "." + name.rsplit(".", 1)[-1].lower() if "." in name else "";
    return ext not in [".png", ".jpg", ".gif", ".wasm", ".zip", ".pyc", ".so"];
}

def keep_files(paths: list) -> list {
    return [rel for rel in paths if is_source(rel)];
}

with entry {
    print(keep_files(['src/main.jac', 'docs/logo.PNG', 'src/__pycache__/main.pyc', '.gitignore', 'README.md']));
}
