node Person {
    has name: str;
}

edge Friend {
    has since: int;
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    charlie = Person(name="Charlie");

    alice +>:Friend(since=2015):+> bob;
    alice +>:Friend(since=2020):+> charlie;

    # Get all friends
    all_friends = [alice -->];
    print(f"Alice has {len(all_friends)} friends");

    # Get specific type of connections
    friends = [alice ->:Friend:->];
    for friend in friends {
        print(friend.name);
    }

    # Filter by edge properties
    old_friends = [alice ->:Friend:since < 2018:->];
}
