node Repo {}
node SrcFile { has path: str; has size: int; }

walker FindBiggest {
    has best_path: str = "", best_size: int = -1;
    can start with Repo entry { visit [-->]; }
    can weigh with SrcFile entry {
        base = here.path.split("/")[-1];
        ext = base.split(".")[-1].lower() if "." in base else "";
        if ext not in ["png", "jpg", "gif", "ico", "wasm", "pyc"] {
            if here.size > self.best_size or (here.size == self.best_size and here.path < self.best_path) {
                self.best_size = here.size;
                self.best_path = here.path;
            }
        }
    }
}

def biggest_source(spec: dict) -> str {
    repo = Repo();
    for f in spec["files"] { repo ++> SrcFile(path=str(f["path"]), size=int(f["size"])); }
    return (repo spawn FindBiggest()).best_path;
}

with entry {
    print(biggest_source({'files': [{'path': 'src/main.jac', 'size': 1200}, {'path': 'assets/logo.png', 'size': 5000}, {'path': 'readme.md', 'size': 800}]}));
}
