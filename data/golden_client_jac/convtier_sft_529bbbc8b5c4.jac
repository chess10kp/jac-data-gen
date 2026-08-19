edge LinksTo {}

node Page { has name: str; has seen: bool = False; }

walker Crawl {
    can step with Page entry {
        if not here.seen {
            here.seen = True;
            visit [->:LinksTo:->];
        }
    }
}

def orphan_pages(spec: dict) -> list {
    pnodes: dict = {};
    for p in spec["pages"] { pnodes[p] = Page(name=str(p)); }
    for lk in spec["links"] {
        if lk[0] in pnodes and lk[1] in pnodes {
            pnodes[lk[0]] +>:LinksTo:+> pnodes[lk[1]];
        }
    }
    start: str = str(spec["start"]);
    if start in pnodes { pnodes[start] spawn Crawl(); }
    orphans: list = [];
    for p in spec["pages"] {
        if not pnodes[p].seen { orphans.append(str(p)); }
    }
    return sorted(orphans);
}

with entry {
    print(orphan_pages({'pages': ['home', 'about', 'blog', 'legacy', 'archive'], 'links': [['home', 'about'], ['about', 'home'], ['home', 'blog'], ['legacy', 'archive']], 'start': 'home'}));
}
