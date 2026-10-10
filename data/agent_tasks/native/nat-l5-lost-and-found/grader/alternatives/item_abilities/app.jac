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

    def open_item -> bool {
        return not [self -->[?:Claim]];
    }

    can offer with search entry {
        if self.open_item()
            and self.category.name == visitor.category
            and self.color.casefold() == visitor.color.casefold()
            and self.found_day >= visitor.since_day {
            visitor.rows.append((self.found_day, self.tag));
        }
    }

    can count_in with stats entry {
        bucket = visitor.table[self.category.name];
        if self.open_item() {
            bucket["open"] = bucket["open"] + 1;
        } else {
            bucket["claimed"] = bucket["claimed"] + 1;
        }
    }
}

node Claim {
    has name: str;
}

edge ClaimedBy: Item --> Claim {}

"""Log a found item; returns its tag (LF-1, LF-2, ...)."""
def:pub log_item(category: str, color: str, found_day: int, location: str) -> str {
    n = len([root -->[?:Item]]) + 1;
    tag = f"LF-{n}";
    root ++> Item(tag=tag, category=Category[category], color=color, found_day=found_day, location=location);
    return tag;
}

walker:pub search {
    has category: str;
    has color: str;
    has since_day: int = 0;
    has rows: list[tuple[int, str]] = [];

    can start with Root entry {
        visit [-->[?:Item]];
    }

    can finish with Root exit {
        self.rows.sort(key=lambda (r: tuple[int, str]) { r[1]; });
        self.rows.sort(key=lambda (r: tuple[int, str]) { r[0]; }, reverse=True);
        report [r[1] for r in self.rows];
    }
}

walker:pub claim {
    has tag: str;
    has name: str;
    has seen: bool = False;

    can start with Root entry {
        visit [-->[?:Item, tag == self.tag]];
    }

    can take with Item entry {
        self.seen = True;
        if not here.open_item() {
            report {"ok": False, "reason": "already claimed"};
            disengage;
        }
        here +>:ClaimedBy():+> Claim(name=self.name);
        report {"ok": True};
    }

    can finish with Root exit {
        if not self.seen {
            report {"ok": False, "reason": "unknown item"};
        }
    }
}

walker:pub expire {
    has today: int;
    has keep_days: int;

    can go with Root entry {
        old = [i for i in [-->[?:Item]] if i.open_item() and i.found_day < self.today - self.keep_days];
        tags = sorted([i.tag for i in old]);
        for i in old {
            del i;
        }
        report tags;
    }
}

walker:pub stats {
    has table: dict[str, dict[str, int]] = {};

    can start with Root entry {
        for name in ["BAG", "PHONE", "UMBRELLA", "KEYS", "OTHER"] {
            self.table[name] = {"open": 0, "claimed": 0};
        }
        visit [-->[?:Item]];
    }

    can finish with Root exit {
        report self.table;
    }
}
