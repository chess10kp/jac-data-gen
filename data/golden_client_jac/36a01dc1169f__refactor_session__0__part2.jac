node Person {
    has name: str;
}
edge Friend {}
walker FindFriends {
    can start with Root entry;
    can find with Person entry;
}
impl FindFriends.start {
    visit [-->];
}
impl FindFriends.find {
    report here.name;
    visit [->:Friend:->];
}
with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    charlie = Person(name="Charlie");
    root ++> alice;
    alice +>:Friend:+> bob;
    alice +>:Friend:+> charlie;
    friends = root spawn FindFriends();
    print(f"Found friends: {friends.reports}");
}
