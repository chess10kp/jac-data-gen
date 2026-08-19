node Person { has name: str; }
edge Friend {}

walker FindFriends {
    has friends: list = [];
    can collect with Person entry {
        for f in [here ->:Friend:->] { self.friends.append(f); }
    }
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    alice +>:Friend:+> bob;
    w = FindFriends();
    alice spawn w;
    print(f"Found {len(w.friends)} friend(s)");
}
