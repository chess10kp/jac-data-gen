edge Contains {}
edge LinksTo {}

node Site {}
node Page { has name: str; }

walker DeadEnds {
    has n: int = 0;
    can start with Site entry { visit [->:Contains:->]; }
    can check with Page entry {
        if len([->:LinksTo:->]) == 0 { self.n += 1; }
    }
}

def dead_pages(spec: dict) -> int {
    site = Site();
    pnodes: dict = {};
    for p in spec["pages"] {
        pg = Page(name=str(p));
        site +>:Contains:+> pg;
        pnodes[p] = pg;
    }
    for lk in spec["links"] {
        if lk[0] in pnodes and lk[1] in pnodes {
            pnodes[lk[0]] +>:LinksTo:+> pnodes[lk[1]];
        }
    }
    return (site spawn DeadEnds()).n;
}

with entry {
    print(dead_pages({'pages': ['home', 'about', 'blog', 'contact'], 'links': [['home', 'about'], ['home', 'blog'], ['blog', 'home']]}));
}
