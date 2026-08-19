node Item {
    has name: str;
}

def calculate_relevance(item: Item, query: str) -> int {
    return 1;
}

walker:priv SearchItems {
    has query: str;
    has matches: list = [];

    can start with Root entry {
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

    can finish with Root exit {
        self.matches.sort(key=lambda x: any: x["score"], reverse=True);
        report self.matches;
    }
}
