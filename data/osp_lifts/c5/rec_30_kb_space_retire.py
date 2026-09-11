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

from collections import deque


class Page:
    def __init__(self, page_id, title):
        self.page_id = page_id
        self.title = title
        self.children = []      # sub-page ids
        self.links = []         # outgoing LinksTo targets
        self.ext_links = 0      # live incoming links from outside retirees


class KbRegistry:
    def __init__(self):
        self.pages = {}         # page_id -> Page

    def add_page(self, page_id, title, parent_id=None):
        self.pages[page_id] = Page(page_id, title)
        if parent_id is not None and parent_id in self.pages:
            self.pages[parent_id].children.append(page_id)
        return self.pages[page_id]

    def link(self, src_id, dst_id):
        if src_id not in self.pages or dst_id not in self.pages:
            return False        # tolerate unknown refs on write
        self.pages[src_id].links.append(dst_id)
        self.pages[dst_id].ext_links += 1
        return True

    def _collect(self, page_id, doomed, spared):
        """Recursive descent; once-only guard against shared reaches."""
        if page_id in doomed or page_id in spared:
            return
        if page_id not in self.pages:
            return              # stale reference tolerated
        page = self.pages[page_id]
        if page.ext_links > 0:
            spared.append(page)  # externally referenced: keep whole subtree
            return
        doomed.append(page)
        for child_id in page.children:
            self._collect(child_id, doomed, spared)

    def retire_space(self, root_id):
        """Retire *root_id* and its exclusively-referenced content.

        Externally-linked pages survive with their subtrees. Returns the
        sorted ids of surviving pages. Unknown ids report [].
        """
        if root_id not in self.pages:
            return []
        root = self.pages[root_id]
        doomed, spared = [], []
        if root.ext_links > 0:
            spared.append(root)
        else:
            doomed.append(root)
            for child_id in root.children:
                self._collect(child_id, doomed, spared)
        # dying holders release their outbound links before removal
        for dead in doomed:
            for target in dead.links:
                if target in self.pages:
                    self.pages[target].ext_links -= 1
            dead.links = []
        for dead in doomed:
            del self.pages[dead.page_id]
        return sorted(s.page_id for s in spared)

    def follow(self, page_id):
        """Live link targets of a page; dangling ones skipped silently."""
        page = self.pages.get(page_id)
        if page is None:
            return []
        return sorted(t for t in page.links if t in self.pages)

    def exists(self, page_id):
        return page_id in self.pages

    def live_pages(self):
        return sorted(self.pages.keys())


if __name__ == "__main__":
    kb = KbRegistry()
    kb.add_page("space", "Space Home")
    kb.add_page("guide", "Guide", parent_id="space")
    kb.add_page("faq", "FAQ", parent_id="space")
    kb.add_page("glossary", "Glossary", parent_id="guide")
    kb.add_page("external", "External Notes")
    assert kb.link("external", "faq")     # outside interest keeps FAQ alive
    print(kb.retire_space("space"), kb.live_pages())
