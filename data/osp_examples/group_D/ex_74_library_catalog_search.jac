"""Library catalog search with relevance scoring.

Books hang off the persistent root. A search walker scans every catalog
entry, scores each one against the query (title matches weigh most, then
author, then tags, with a small bonus for recent titles), and ranks the
hits best-first with a lambda-key sort once the walk completes.
"""

node Book {
    has title: str;
    has author: str;
    has year: int;
    has tags: list[str] = [];
}

walker CatalogSearch {
    has query: str;
    has hits: list[dict] = [];

    def score_book(bk: Book) -> int {
        total = 0;
        q = self.query.lower();
        if q in bk.title.lower() {
            total += 10;
        }
        if q in bk.author.lower() {
            total += 6;
        }
        for tag in bk.tags {
            if q in tag.lower() {
                total += 4;
            }
        }
        if bk.year >= 2020 {
            total += 1;
        }
        return total;
    }

    can start with Root entry {
        visit [-->];
    }

    can scan with Book entry {
        score = self.score_book(here);
        if score > 0 {
            self.hits.append({"title": here.title, "score": score});
        }
        # No visit: the scan stops at each book on purpose.
    }

    can finish with Root exit {
        # Deferred until the whole catalog has been scanned.
        self.hits.sort(key=lambda (h: any) { h["score"]; }, reverse=True);
        n = len(self.hits);
        shown = n if n < 3 else 3;
        print(f"Top {shown} result(s) for '{self.query}' out of {n} hit(s):");
        for i in range(shown) {
            print(f"  {self.hits[i]['score']:>2} pts  {self.hits[i]['title']}");
        }
    }
}

with entry {
    for stale in [root -->][?:Book] {
        del stale;
    }

    root ++> Book(
        title="Robot Dreams and Walkers", author="R. Vega", year=2021,
        tags=["robotics", "agents"],
    );
    root ++> Book(
        title="The Graphene Garden", author="T. Okafor", year=2019,
        tags=["science-fiction", "materials"],
    );
    root ++> Book(
        title="Practical Robotics", author="M. Chen", year=2023,
        tags=["robotics", "engineering", "hands-on"],
    );
    root ++> Book(
        title="Cooking for Two", author="L. Romero", year=2018,
        tags=["cooking"],
    );
    root ++> Book(
        title="Robot Ethics", author="P. Singh", year=2022,
        tags=["robotics", "philosophy"],
    );

    root spawn CatalogSearch(query="robot");
}
