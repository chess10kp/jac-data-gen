"""Guard for rec_30_kb_space_retire -- candidate OSP lift inlined verbatim
(same-prefix sibling imports are unreliable across jac's native seam), plus
behavioral tests: external-backlink sparing (diamond closure stops at the
boundary), full retirement without external interest, dangling/unknown
reference tolerance on both write and read paths.
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

test "retire_spares_externally_linked_pages" {
    kb = load_graph(
        spec=[("space", "Space Home", None),
              ("guide", "Guide", "space"),
              ("faq", "FAQ", "space"),
              ("glossary", "Glossary", "guide"),
              ("external", "External Notes", None)],
        links=[("external", "faq"), ("external", "guide")]
    );
    spared = kb.retire_space("space");
    # faq and guide carry incoming links from outside: spared with subtree
    assert spared == ["faq", "guide"];
    assert not kb.exists("space");
    assert kb.exists("faq") and kb.exists("guide") and kb.exists("glossary");
}

test "unreferenced_branch_fully_retires" {
    kb = load_graph(
        spec=[("solo_space", "Solo", None), ("deep", "Deep", "solo_space"),
              ("other", "Other", None)],
        links=[("deep", "other")]
    );
    spared = kb.retire_space("solo_space");
    assert spared == [];
    assert not kb.exists("solo_space") and not kb.exists("deep");
    assert kb.exists("other");
}

test "unknown_and_dangling_tolerated" {
    kb = load_graph(
        spec=[("a", "A", None), ("b", "B", None)],
        links=[]
    );
    assert kb.retire_space("ghost") == [];
    ok = kb.link("a", "ghost");          # dangling link refused
    assert ok is False;
    assert kb.follow("a") == [];
}
