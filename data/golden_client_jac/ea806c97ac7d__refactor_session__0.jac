node Person {
    has name: str;
}

edge Friend {}

walker ListFriends {
    can run with Person entry {
        print(f"{here.name}'s friends:");
        for friend in [here<-->] {
            print(f"  - {friend.name}");
        }
    }
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    charlie = Person(name="Charlie");

    alice <+:Friend:+> bob;
    alice <+:Friend:+> charlie;
    bob <+:Friend:+> charlie;

    alice spawn ListFriends();
}
