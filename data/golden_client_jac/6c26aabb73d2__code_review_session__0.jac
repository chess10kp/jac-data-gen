node Person {
    has name: str;
}

edge Friend {}
edge Family {}

with entry {
    p1 = Person(name="John");
    p2 = Person(name="Susan");
    p3 = Person(name="Mike");
    root ++> p1;
    p1 +>:Friend:+> p2;
    p2 +>:Family:+> [p1, p3];
}
