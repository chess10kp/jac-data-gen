node Drive {}
node Folder { has name: str; }
node StoredFile { has size: int; }

walker Usage {
    has tally: dict = {}, result: dict = {};
    can start with Drive entry { visit [-->]; }
    can measure with Folder entry {
        total = 0;
        for f in [-->] { total += f.size; }
        self.tally[here.name] = self.tally.get(here.name, 0) + total;
    }
    can arrange with exit {
        for k in sorted(self.tally.keys()) { self.result[k] = self.tally[k]; }
    }
}

def dir_usage(spec: dict) -> dict {
    drive = Drive();
    folders: dict = {};
    for f in spec["files"] {
        top = f["path"].split("/")[0] if "/" in f["path"] else "(root)";
        if top not in folders {
            fd = Folder(name=top);
            drive ++> fd;
            folders[top] = fd;
        }
        folders[top] ++> StoredFile(size=int(f["size"]));
    }
    return (drive spawn Usage()).result;
}

with entry {
    print(dir_usage({'files': [{'path': 'src/main.jac', 'size': 100}, {'path': 'src/util.jac', 'size': 50}, {'path': 'docs/a.md', 'size': 30}, {'path': 'README', 'size': 10}]}));
}
