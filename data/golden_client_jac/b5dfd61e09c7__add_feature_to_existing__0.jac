node Person {
    has age: int,
        verified: bool = False,
        can_vote: bool = False;
}

node Item {
    has status: str,
        processed_at: str,
        archived: bool = False;
}

def now() -> str {
    return "2024-01-01";
}

def example(people: list[Person], items: list[Item]) {
    # Set attribute on all items
    people(=verified=True);

    # Chained: filter then assign
    people[?age >= 18](=can_vote=True);

    # Multiple assignments
    items(=status="processed", processed_at=now());

    # Archive every already-processed item in one filtered assignment
    items[?status == "processed"](=archived=True);
}
