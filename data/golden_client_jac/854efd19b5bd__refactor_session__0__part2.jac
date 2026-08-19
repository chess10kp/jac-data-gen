node Person {
    has name: str;
}
edge Friend {}
walker FindFriends {
    has friends: list = [];
    can start with Root entry;
    can collect with Person entry;
}
impl FindFriends.start {
    visit [-->];
}
impl FindFriends.collect {
    for f in [here ->:Friend:->] {
        self.friends.append(f);
    }
}
with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    root ++> alice;
    alice +>:Friend:+> bob;
    w = FindFriends();
    root spawn w;
    print(f"Found {len(w.friends)} friend(s)");
}
