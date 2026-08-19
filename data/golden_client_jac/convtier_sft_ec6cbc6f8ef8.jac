node Person3 {
    has name: str;
}

edge Friend3 {}

edge Block3 {}

walker CountFriends {
    has count: int = 0;

    can chk with Person3 entry {
        self.count += len([->:Friend3:->]);
        visit [-->];
    }
}

with entry {
    a = Person3(name="a");
    b = Person3(name="b");
    c = Person3(name="c");
    d = Person3(name="d");
    root ++> a;
    a +>:Friend3:+> b;
    a +>:Friend3:+> c;
    a +>:Block3:+> d;
    w = a spawn CountFriends();
    print(w.count);
}
