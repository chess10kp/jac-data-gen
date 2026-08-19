node Person {
    has name: str;
    can announce with FriendFinder entry;
}
edge Friend {}
edge Family {
    can announce with FriendFinder entry;
}
walker FriendFinder {
    has started: bool = False;
    can report_friend with Person entry {
        if self.started {
            print(f"{here.name} is a friend of friend, or family");
        } else {
            self.started = True;
            visit [-->];
        }
        visit [edge ->:Family :->];
    }
    can move_to_person with Root entry;
}
impl Person.announce {
    print(f"{visitor} is checking me out");
}
impl Family.announce {
    print(f"{visitor} is traveling to family member");
}
impl FriendFinder.move_to_person {
    visit [-->];
}
with entry {
    p1 = Person(name="John");
    p2 = Person(name="Susan");
    p3 = Person(name="Mike");
    p4 = Person(name="Alice");
    root ++> p1;
    p1 +>: Friend :+> p2;
    p2 +>: Family :+> [p1, p3];
    p2 +>: Friend :+> p3;
}
with entry {
    result = FriendFinder() spawn root;
    print(result);
}
