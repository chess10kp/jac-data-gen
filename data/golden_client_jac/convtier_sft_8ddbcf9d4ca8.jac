node Folder { has name: str; }
node File { has name: str; }

walker PruneCount {
    has exclude: list;
    has total: int = 0;
    can scan with Folder entry {
        if here.name not in self.exclude {
            self.total += len([-->][?:File]);
            visit [-->][?:Folder];
        }
    }
}

def prune_count(spec: dict) -> int {
    top = Folder(name=str(spec["tree"]["name"]));
    stack: list = [(spec["tree"], top)];
    while len(stack) > 0 {
        item = stack.pop();
        d = item[0];
        parent = item[1];
        for fname in d["files"] { parent ++> File(name=str(fname)); }
        for sub in d["dirs"] {
            child = Folder(name=str(sub["name"]));
            parent ++> child;
            stack.append((sub, child));
        }
    }
    exclude: list = [str(x) for x in spec["exclude"]];
    return (top spawn PruneCount(exclude=exclude)).total;
}

with entry {
    print(prune_count({'tree': {'name': 'repo', 'files': ['README.md'], 'dirs': [{'name': 'node_modules', 'files': ['a.js', 'b.js', 'c.js'], 'dirs': [{'name': 'lodash', 'files': ['index.js'], 'dirs': []}]}, {'name': 'src', 'files': ['app.js', 'db.js'], 'dirs': [{'name': '.git', 'files': ['HEAD'], 'dirs': []}]}]}, 'exclude': ['node_modules', '.git']}));
}
