node Item {
    has name: str;
}

walker:priv FindMatches {
    has search_term: str,
        reports: list[Item] = [];   # one Item per match

    can search with Root entry {
        visit [-->];
    }

    can check with Item entry {
        if self.search_term in here.name {
            report here;  # `here` is Item -- type-checked against list[Item]
        }
    }
}

with entry {
    # Usage
    result = root spawn FindMatches(search_term="test");
    matches: list[Item] = result.reports;  # typed end-to-end
}
