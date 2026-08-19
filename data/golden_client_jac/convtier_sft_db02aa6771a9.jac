node Folder { has name: str; }
node File { has name: str, size: int; }

walker SizeSum {
    has total: int = 0;
    can scan with Folder entry {
        for f in [-->][?:File] { self.total += f.size; }
        visit [-->][?:Folder];
    }
}

def tree_size(spec: dict) -> int {
    top = Folder(name=str(spec["tree"]["name"]));
    stack: list = [(spec["tree"], top)];
    while len(stack) > 0 {
        item = stack.pop();
        d = item[0];
        parent = item[1];
        for (fname, size) in d["files"] { parent ++> File(name=str(fname), size=int(size)); }
        for sub in d["dirs"] {
            child = Folder(name=str(sub["name"]));
            parent ++> child;
            stack.append((sub, child));
        }
    }
    return (top spawn SizeSum()).total;
}

with entry {
    print(tree_size({'tree': {'name': 'root', 'files': [['readme.md', 10]], 'dirs': [{'name': 'src', 'files': [['main.py', 120], ['util.py', 20]], 'dirs': [{'name': 'core', 'files': [['engine.py', 200]], 'dirs': []}]}, {'name': 'assets', 'files': [['logo.png', 50]], 'dirs': []}]}}));
}
