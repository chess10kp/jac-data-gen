node Tree {}
node Folder { has name: str; }
node Leaf { has name: str; }

walker KeepCount {
    has kept: int = 0;
    can start with Tree entry { visit [-->]; }
    can dive with Folder entry {
        if here.name != "__pycache__" { visit [-->]; }
    }
    can check with Leaf entry {
        ext = here.name.split(".")[-1].lower() if "." in here.name else "";
        if not here.name.startswith(".") and ext not in ["png", "jpg", "gif", "ico", "wasm", "pyc"] {
            self.kept += 1;
        }
    }
}

def count_kept_files(spec: dict) -> int {
    tree = Tree();
    folders: dict = {};
    for path in spec["paths"] {
        segs: list = path.split("/");
        parent = tree;
        prefix = "";
        for d in segs[:-1] {
            prefix = prefix + "/" + d;
            if prefix not in folders {
                nd = Folder(name=d);
                parent ++> nd;
                folders[prefix] = nd;
            }
            parent = folders[prefix];
        }
        parent ++> Leaf(name=segs[-1]);
    }
    return (tree spawn KeepCount()).kept;
}

with entry {
    print(count_kept_files({'paths': ['src/main.jac', 'a/__pycache__/x.pyc', 'dir/.hidden', 'logo.PNG', 'readme.md']}));
}
