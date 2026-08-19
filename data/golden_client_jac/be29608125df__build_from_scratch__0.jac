node Person {
    has name: str;
}

edge Follows {
    has since: int = 2024;
}

with entry {
    alice = Person(name="alice");
    bob   = Person(name="bob");
    carol = Person(name="carol");

    root ++> alice;
    alice +>:Follows(since=2020):+> bob;
    alice +>:Follows(since=2023):+> carol;

    all_out     = [alice -->];
    via_follows = [alice ->:Follows:->];
    print([n.name for n in all_out]);
    print([n.name for n in via_follows]);
}
