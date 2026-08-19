# Jac OSP approach - Concise, declarative, type-safe
node Person {
    has name: str;
}

edge Friend {
}

walker FindFriends {
    can start with Root entry {
        visit [-->];
    }

    can find with Person entry {
        report here.name;
        visit [->:Friend:->];
    }
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
