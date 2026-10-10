"""Lost-property desk for a transit operator.

root --> Item ; Item -ClaimedBy-> Claim once an owner collects it.
"""

enum Category {
    BAG,
    PHONE,
    UMBRELLA,
    KEYS,
    OTHER
}

node Item {
    has tag: str;
    has category: Category;
    has color: str;
    has found_day: int;
    has location: str = "";
}

node Claim {
    has name: str;
}

edge ClaimedBy: Item --> Claim {}

"""Look up a Category member by its name (None if there is no such member)."""
def category_named(label: str) -> Category | None {
    for m in Category {
        if m.name == label {
            return m;
        }
    }
    return None;
}

"""Log a found item; returns its tag (LF-1, LF-2, ...)."""
def:pub log_item(category: str, color: str, found_day: int, location: str) -> str {
    n = len([root -->[?:Item]]) + 1;
    tag = f"LF-{n}";
    root ++> Item(tag=tag, category=category_named(category) or Category.OTHER, color=color, found_day=found_day, location=location);
    return tag;
}

def is_claimed(it: Item) -> bool {
    return len([it ->:ClaimedBy:->]) > 0;
}

walker:pub search {
    has category: str;
    has color: str;
    has since_day: int = 0;
    has hits: list[Item] = [];

    can start with Root entry {
        visit [-->[?:Item]];
    }

    can match_item with Item entry {
        if is_claimed(here) {
            return;
        }
        if here.category.name == self.category
            and here.color.lower() == self.color.lower()
            and here.found_day >= self.since_day {
            self.hits.append(here);
        }
    }

    can finish with Root exit {
        ordered = sorted(self.hits, key=lambda (i: Item) { (-i.found_day, i.tag); });
        report [i.tag for i in ordered];
    }
}

walker:pub claim {
    has tag: str;
    has name: str;

    can collect with Root entry {
        items = [i for i in [root -->[?:Item]] if i.tag == self.tag];
        if not items {
            report {"ok": False, "reason": "unknown item"};
            return;
        }
        it = items[0];
        if is_claimed(it) {
            report {"ok": False, "reason": "already claimed"};
            return;
        }
        it +>:ClaimedBy():+> Claim(name=self.name);
        report {"ok": True};
    }
}

walker:pub expire {
    has today: int;
    has keep_days: int;
    has gone: list[str] = [];

    can start with Root entry {
        visit [-->[?:Item]];
    }

    can check with Item entry {
        if not is_claimed(here) and self.today - here.found_day > self.keep_days {
            self.gone.append(here.tag);
            del here;
        }
    }

    can finish with Root exit {
        report sorted(self.gone);
    }
}

walker:pub stats {
    has counts: dict[str, dict[str, int]] = {};

    can start with Root entry {
        for c in Category {
            self.counts[c.name] = {"open": 0, "claimed": 0};
        }
        visit [-->[?:Item]];
    }

    can tally with Item entry {
        key = "claimed" if is_claimed(here) else "open";
        self.counts[here.category.name][key] += 1;
    }

    can finish with Root exit {
        report self.counts;
    }
}
