"""Knowledge-base spaces with cascade retirement and backlink safety.

Spaces contain pages (``Contains``). Pages may link to other pages
(``LinksTo``); a page targeted by a link from OUTSIDE the retiring set is
kept alive -- only its containment in the retired space goes away -- while
exclusively-contained pages are deleted together with their exclusive
sub-pages. Readers that follow links to retired pages skip them silently
(dangling backlinks are data, not errors). ``ext_links`` counts incoming
links from pages outside the page's own subtree and is maintained as the
graph changes.
"""
import from collections { deque }
class Page {
    has page_id: str;
    has title: str;
    has children: list[str] = [];
    has links: list[str] = [];
    has ext_links: int = 0;
    def init(self: Page, page_id: str, title: str) -> object {
        self.page_id = page_id;
        self.title = title;
        self.children = [];
        self.links = [];
        self.ext_links = 0;
    }
}
class KbRegistry {
    has pages: dict[str, Page];
    def init(self: KbRegistry) -> object {
        self.pages = {};
    }
    def add_page(
        self: KbRegistry, page_id: str, title: str, parent_id: str | None = None
    ) -> object {
        self.pages[page_id] = Page(page_id, title);
        if ((parent_id is not None) and (parent_id in self.pages)) {
            self.pages[parent_id].children.append(page_id);
        }
        return self.pages[page_id];
    }
    def link(self: KbRegistry, src_id: str, dst_id: str) -> object {
        if ((src_id not in self.pages) or (dst_id not in self.pages)) {
            return False;
        }
        self.pages[src_id].links.append(dst_id);
        self.pages[dst_id].ext_links += 1;
        return True;
    }
    def _collect(self: KbRegistry, page_id: str, doomed: list[Page], spared: list[Page]) -> object {
        if ((page_id in doomed) or (page_id in spared)) {
            return;
        }
        if (page_id not in self.pages) {
            return;
        }
        page = self.pages[page_id];
        if (page.ext_links > 0) {
            spared.append(page);
            return;
        }
        doomed.append(page);
        for child_id in page.children {
            self._collect(child_id, doomed, spared);
        }
    }
    def retire_space(self: KbRegistry, root_id: str) -> object {
        if (root_id not in self.pages) {
            return [];
        }
        `root = self.pages[root_id];
        (doomed, spared) = ([], []);
        if (`root.ext_links > 0) {
            spared.append(`root);
        } else {
            doomed.append(`root);
            for child_id in `root.children {
                self._collect(child_id, doomed, spared);
            }
        }
        for dead in doomed {
            for target in dead.links {
                if (target in self.pages) {
                    self.pages[target].ext_links -= 1;
                }
            }
            dead.links = [];
        }
        for dead in doomed {
            delete(self.pages[dead.page_id],);
        }
        return sorted(s.page_id for s in spared);
    }

    def follow(self: KbRegistry, page_id: str) -> object {
        page = self.pages.get(page_id);
        if (page is None) {
            return [];
        }
        return sorted(
            t
            for t in page.links
            if (t in self.pages)
        );
    }
    def exists(self: KbRegistry, page_id: Any) -> object {
        return (page_id in self.pages);
    }
    def live_pages(self: KbRegistry) -> object {
        return sorted(self.pages.keys());
    }
}

with entry {
    if (__name__ == "__main__") {
        kb = KbRegistry();
        kb.add_page("space", "Space Home");
        kb.add_page("guide", "Guide", parent_id="space");
        kb.add_page("faq", "FAQ", parent_id="space");
        kb.add_page("glossary", "Glossary", parent_id="guide");
        kb.add_page("external", "External Notes");
        assert kb.link("external", "faq");
        print(kb.retire_space("space"), kb.live_pages());
    }
}

