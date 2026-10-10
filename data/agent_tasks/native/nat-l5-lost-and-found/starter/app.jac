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

"""Log a found item; returns its tag (LF-1, LF-2, ...)."""
def:pub log_item(category: str, color: str, found_day: int, location: str) -> str {
    n = len([root -->[?:Item]]) + 1;
    tag = f"LF-{n}";
    root ++> Item(tag=tag, category=Category[category], color=color, found_day=found_day, location=location);
    return tag;
}
