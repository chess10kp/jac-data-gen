"""Blog hit counter: one PageCounter node per page, bumped by a public walker."""

node PageCounter {
    has page: str;
    has visits: int = 0;
}

walker:pub record_visit {
    has page: str;

    can count with Root entry {
        name = self.page.strip();
        if not name {
            report {"error": "page required"};
            return;
        }
        visit [here -->[?:PageCounter, page == name]] else {
            visit here ++> PageCounter(page=name);
        }
    }

    can bump with PageCounter entry {
        here.visits += 1;
        report {"page": here.page, "visits": here.visits};
    }
}
