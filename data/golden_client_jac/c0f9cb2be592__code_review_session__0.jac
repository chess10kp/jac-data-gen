node Item {
    has name: str;
}

def calculate_relevance(item: Item, query: str) -> int {
    return len(query);
}

def by_score(m: dict[str, any]) -> int {
    return int(m["score"]);
}

walker:priv SearchItems {
    has query: str;
    has matches: list[dict[str, any]] = [];

    can start with `root entry {
        visit [-->];
    }

    can check with Item entry {
        if self.query.lower() in here.name.lower() {
            self.matches.append({
                "id": jid(here),
                "name": here.name,
                "score": calculate_relevance(here, self.query)
            });
        }
    }

    can finish with `root exit {
        self.matches.sort(key=by_score, reverse=True);
        report self.matches;
    }
}
