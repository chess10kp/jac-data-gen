node Folder { has name: str; }
node File { has name: str, size: int; }

walker LangTally {
    has totals: dict = {}, report: str = "";
    can scan with Folder entry { visit [-->]; }
    can note with File entry {
        if "." in here.name { ext = here.name.rsplit(".", 1)[1]; }
        else { ext = "plain"; }
        self.totals[ext] = self.totals.get(ext, 0) + here.size;
    }
    can fmt with exit {
        parts: list = [];
        for ext in sorted(self.totals.keys()) {
            parts.append(ext + "=" + str(self.totals[ext]));
        }
        self.report = ", ".join(parts);
    }
}

def lang_report(spec: dict) -> str {
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
    return (top spawn LangTally()).report;
}

with entry {
    print(lang_report({'tree': {'name': 'root', 'files': [['readme.md', 10], ['LICENSE', 3]], 'dirs': [{'name': 'src', 'files': [['main.py', 120], ['util.py', 20], ['notes.md', 5]], 'dirs': []}]}}));
}
