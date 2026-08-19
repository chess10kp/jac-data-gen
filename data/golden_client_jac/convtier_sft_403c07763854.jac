node Repo {}
node Folder { has name: str; }
node File { has name: str, size: int; }

walker ExtCount {
    has ext: str;
    has total: int = 0;
    can start with Repo entry { visit [-->][?:Folder]; }
    can scan with Folder entry {
        for f in [-->][?:File] {
            if f.name.endswith(self.ext) { self.total += 1; }
        }
    }
}

def count_ext(spec: dict) -> int {
    repo = Repo();
    for folder in spec["folders"] {
        fo = Folder(name=str(folder["name"]));
        repo ++> fo;
        for (fname, size) in folder["files"] {
            fo ++> File(name=str(fname), size=int(size));
        }
    }
    return (repo spawn ExtCount(ext=str(spec["ext"]))).total;
}

with entry {
    print(count_ext({'folders': [{'name': 'src', 'files': [['main.py', 120], ['util.py', 80], ['notes.md', 10]]}, {'name': 'docs', 'files': [['index.md', 5], ['app.py', 64]]}], 'ext': '.py'}));
}
