node Person {
    has name: str;
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    carol = Person(name="Carol");

    root ++> alice;
    alice ++> bob;
    alice ++> carol;

    # Query connections from root
    people = [root -->];  # All nodes connected to root
    print(len(people));   # 1 (alice)

    # Query from alice
    friends = [alice -->];  # [bob, carol]

    # Filter by type
    only_people = [root -->][?:Person];
}
