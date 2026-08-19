node Repo {}
node SrcFile { has path: str; }

walker Census {
    has tally: dict = {}, result: dict = {};
    can start with Repo entry { visit [-->]; }
    can label with SrcFile entry {
        labels: dict = {"py": "Python", "md": "Markdown", "toml": "TOML", "css": "CSS", "js": "JavaScript"};
        base = here.path.split("/")[-1];
        if here.path.endswith(".jac") { lab = "Jac"; }
        elif "." in base {
            ext = base.split(".")[-1].lower();
            lab = labels.get(ext, ext.upper());
        }
        else { lab = "Text"; }
        self.tally[lab] = self.tally.get(lab, 0) + 1;
    }
    can arrange with exit {
        for k in sorted(self.tally.keys()) { self.result[k] = self.tally[k]; }
    }
}

def lang_census(spec: dict) -> dict {
    repo = Repo();
    for p in spec["paths"] { repo ++> SrcFile(path=str(p)); }
    return (repo spawn Census()).result;
}

with entry {
    print(lang_census({'paths': ['main.jac', 'app.py', 'docs/readme.md', 'web/style.css', 'util.py']}));
}
