"""Idiomatic OSP lift: KB space retirement with backlink safety
(category C5, two-phase §5.5).

Phase COLLECT -- `RetireScan` walks `Contains` edges gathering doomed and
spared pages into typed `has` fields. A page with live incoming links from
outside the retiring set (`ext_links > 0`) is a shared boundary: spared
with its whole subtree, siblings continue (`skip;`). The seen-guard is the
once-only diamond guard and the explicit cycle policy (no built-in dedup
in 0.36.1).

Phase APPLY -- outside any walk: dying pages release their outbound links,
are disconnected and destroyed; readers skip dangling targets silently.
The source's deque/queue sweep and reverse bookkeeping die -- the counter
lives on the node and is maintained when links are written.
"""

node Page {
    has page_id: str;
    has title: str;
    has ext_links: int = 0;     # live incoming links from outside retirees
}

edge Contains { }
edge LinksTo { }

"""Split one space subtree into doomed and spared pages."""
walker RetireScan {
    has root_id: str;
    has doomed: list[Page] = [];
    has spared: list[Page] = [];
    has seen: dict[str, bool] = {};

    can scan with Page entry {
        if here.page_id in self.seen {
            skip;               # revisit / cycle policy: decide once only,
        }                       # keep sibling branches alive
        self.seen[here.page_id] = True;
        if here.page_id != self.root_id and here.ext_links > 0 {
            self.spared.append(here);   # external interest: keep subtree
            skip;
        }
        self.doomed.append(here);
        visit [->:Contains:->];
    }
}

obj KbRegistry {
    has pages: dict[str, Page];

    def add_page(page_id: str, title: str, parent_id: str | None = None)
            -> Page {
        fresh = Page(page_id=page_id, title=title);
        self.pages[page_id] = fresh;
        if parent_id is not None and parent_id in self.pages {
            parent = self.pages[parent_id];
            parent +>:Contains:+> fresh;
        }
        return fresh;
    }

    def link(src_id: str, dst_id: str) -> bool {
        source = self.pages.get(src_id);
        target = self.pages.get(dst_id);
        if source is None or target is None {
            return False;               # tolerate unknown refs on write
        }
        source +>:LinksTo:+> target;
        target.ext_links += 1;
        return True;
    }

    """Retire *root_id* + exclusively-referenced content.

    Externally-linked pages survive with their subtrees. Returns the
    sorted ids of surviving pages; unknown ids report [].
    """
    def retire_space(root_id: str) -> list[str] {
        start = self.pages.get(root_id);
        if start is None {
            return [];
        }
        # Phase COLLECT -- walk once, mutate never.
        scan = start spawn RetireScan(root_id=root_id);

        # Phase APPLY -- mutation strictly after the walk finished.
        for dead in scan.doomed {
            targets = [dead ->:LinksTo:->] as list[Page];
            for t in targets {
                t.ext_links -= 1;       # dying link releases its hold
                dead del ->:LinksTo:-> t;
            }
            holder = dead.page_id;
            del dead;
            _gone = self.pages.pop(holder, None);
        }
        return sorted(s.page_id for s in scan.spared);
    }

    """Live link targets of a page; dangling ones skipped silently."""
    def follow(page_id: str) -> list[str] {
        page = self.pages.get(page_id);
        if page is None {
            return [];
        }
        targets = [page ->:LinksTo:->] as list[Page];
        return sorted(t.page_id for t in targets);
    }

    def exists(page_id: str) -> bool {
        return page_id in self.pages;
    }

    def live_pages -> list[str] {
        return sorted(self.pages.keys());
    }
}

"""Build a fresh deterministic registry; creation order = fixture order."""
def load_graph(spec: list[tuple[str, str, str | None]],
               links: list[tuple[str, str]]) -> KbRegistry {
    kb = KbRegistry(pages={});
    for row in spec {
        _made = kb.add_page(row[0], row[1], row[2]);
    }
    for pair in links {
        _ok = kb.link(pair[0], pair[1]);
    }
    return kb;
}
