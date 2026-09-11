"""Stylesheet import inlining with visited-URL and fetch-budget bounds.

barkandbite/cerberus#286: inline_imports bounds recursion depth but not
breadth, total fetches, or repeats -- one hostile sheet fans out to
N^4 blocking fetches because there is no visited-URL set and no budget.
The in-memory core below models the stylesheet pool as a lookup table (the
"fetch" is a dict read, counted) and implements the hardened contract:
each URL fetched at most once per inline run, an explicit fetch budget,
and the source's depth cap preserved. The hand-rolled machinery is the
recursive splice with its bookkeeping containers.
"""


class BudgetExceeded(RuntimeError):
    """The inline pass hit its fetch budget."""


class StyleSheetPool:
    def __init__(self):
        self.sheets = {}   # url -> {"body": str, "imports": [url]}
        self.fetches = {}  # url -> count

    def register(self, url, body, imports):
        self.sheets[url] = {"body": body, "imports": list(imports)}

    def fetch(self, url):
        if url not in self.sheets:
            raise KeyError(url)
        self.fetches[url] = self.fetches.get(url, 0) + 1
        return self.sheets[url]

    def fetch_count(self, url):
        return self.fetches.get(url, 0)


class Inliner:
    def __init__(self, pool, max_depth=4, max_fetches=1000):
        self.pool = pool
        self.max_depth = max_depth
        self.max_fetches = max_fetches

    def inline_closure(self, root_url):
        """Sorted urls transitively reachable via @import from root.

        Each url fetched once regardless of how many sheets import it;
        depth cap and fetch budget are enforced; the root itself is not
        part of the closure.
        """
        seen = set()
        spent = [0]

        def walk(url, depth):
            if depth >= self.max_depth:
                return
            if url in seen:
                return  # repeat import: fetch nothing
            if spent[0] >= self.max_fetches:
                raise BudgetExceeded("fetch budget exhausted")
            meta = self.pool.fetch(url)
            spent[0] += 1
            seen.add(url)
            for child in meta["imports"]:  # recursive splice
                walk(child, depth + 1)

        walk(root_url, 0)
        return sorted(seen - {root_url})

    def total_bytes(self, root_url):
        return sum(
            len(self.pool.sheets[u]["body"]) for u in self.inline_closure(root_url)
        )
