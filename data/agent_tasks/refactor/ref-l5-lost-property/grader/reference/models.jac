"""Lost-property graph model.

root --> Station -Holds-> Item -ClaimedBy(day)-> Claimant
A claimed item stays under its station but is no longer held for search.
"""

enum Category {
    BAG = "bag",
    PHONE = "phone",
    UMBRELLA = "umbrella",
    KEYS = "keys",
    OTHER = "other"
}

node Station {
    has name: str;
    has issued: int = 0;

    def next_tag -> str;
}

node Item {
    has tag: str;
    has category: Category;
    has color: str;
    has day: int;

    def is_claimed -> bool;
    def matches(category: Category, color: str, since_day: int) -> bool;
}

node Claimant {
    has name: str;
}

edge Holds: Station --> Item {}

edge ClaimedBy: Item --> Claimant {
    has day: int;
}

def category_named(name: str) -> Category | None;
