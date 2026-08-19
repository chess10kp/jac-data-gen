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

    root ++> alice;                              # untyped connection
    alice +>:Follows(since=2020):+> bob;           # typed connection with has fields
    alice +>:Follows(since=2023):+> carol;

    all_out     = [alice -->];                     # every outgoing node
    via_follows = [alice ->:Follows:->];           # filter by edge type (single-arrow form)
    typed_nodes = [root -->][?:Person];          # filter by node type
    named_bob   = [alice -->][?name == "bob"];     # node-field predicate

    print([n.name for n in all_out]);
    print([n.name for n in via_follows]);
    print([n.name for n in typed_nodes]);
    print([n.name for n in named_bob]);
}
