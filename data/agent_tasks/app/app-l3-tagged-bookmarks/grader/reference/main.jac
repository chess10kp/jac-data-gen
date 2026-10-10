"""Bookmark manager: Bookmark nodes tagged via shared Tag nodes."""

import sys;

node Bookmark {
    has url: str;
    has title: str = "";
}

node Tag {
    has name: str;
}

edge Tagged: Bookmark --> Tag {}

def clean_tags(tags: list[str]) -> list[str] {
    out: list[str] = [];
    for t in tags {
        c = t.strip().lower();
        if c and c not in out {
            out.append(c);
        }
    }
    return out;
}

def find_bookmark(url: str) -> Bookmark | None {
    for b in [root -->[?:Bookmark]] {
        if b.url == url {
            return b;
        }
    }
    return None;
}

walker SaveBookmark {
    has url: str;
    has title: str = "";
    has tags: list[str] = [];

    can save with Root entry {
        bm = find_bookmark(self.url);
        if bm is None {
            bm = here ++> Bookmark(url=self.url, title=self.title);
        } else {
            bm.title = self.title;
        }
        have = [t.name for t in [bm ->:Tagged:->]];
        for name in clean_tags(self.tags) {
            if name in have {
                continue;
            }
            existing = [t for t in [here -->[?:Tag]] if t.name == name];
            tag = existing[0] if existing else here ++> Tag(name=name);
            bm +>:Tagged:+> tag;
        }
        report bm;
    }
}

walker FindByTag {
    has tag: str;

    can find with Root entry {
        want = self.tag.strip().lower();
        urls: list[str] = [];
        for t in [here -->[?:Tag]] {
            if t.name == want {
                urls = [b.url for b in [t <-:Tagged:<-]];
            }
        }
        report sorted(urls);
    }
}

walker TagCounts {
    can count with Root entry {
        counts: dict[str, int] = {};
        for t in [here -->[?:Tag]] {
            n = len([t <-:Tagged:<-]);
            if n > 0 {
                counts[t.name] = n;
            }
        }
        report counts;
    }
}

walker DeleteBookmark {
    has url: str;

    can remove with Root entry {
        bm = find_bookmark(self.url);
        if bm is None {
            report False;
            return;
        }
        del bm;
        # drop tags that no bookmark uses any more
        for t in [here -->[?:Tag]] {
            if len([t <-:Tagged:<-]) == 0 {
                del t;
            }
        }
        report True;
    }
}

def run_cli(argv: list[str]) -> int {
    cmd = argv[0] if argv else "";
    if cmd == "save" and len(argv) >= 3 {
        tags = argv[3].split(",") if len(argv) > 3 else [];
        root spawn SaveBookmark(url=argv[1], title=argv[2], tags=tags);
        print(f"saved {argv[1]}");
    } elif cmd == "find" and len(argv) == 2 {
        urls = (root spawn FindByTag(tag=argv[1])).reports[0];
        if not urls {
            print("no bookmarks");
        }
        for u in urls {
            print(u);
        }
    } elif cmd == "tags" {
        counts = (root spawn TagCounts()).reports[0];
        for name in sorted(counts.keys()) {
            print(f"{name} {counts[name]}");
        }
    } elif cmd == "delete" and len(argv) == 2 {
        ok = (root spawn DeleteBookmark(url=argv[1])).reports[0];
        print("deleted" if ok else "not found");
    } else {
        print("usage: save URL TITLE TAGS | find TAG | tags | delete URL");
        return 2;
    }
    return 0;
}

with entry:__main__ {
    sys.`exit(run_cli(sys.argv[1:]));
}
