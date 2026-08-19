node Person {
    has name: str;
}
edge Friend {
    has since: int;
}
walker Greeter {
    can start with Root entry;
    can greet with Person entry;
}
impl Greeter.start {
    visit [-->];
}
impl Greeter.greet {
    print(f"Hello, {here.name}!");
    visit [-->];
}
with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    root ++> alice;
    alice ++> bob;
    alice +>:Friend(since=2020):+> bob;
    friends = [alice ->:Friend:->];
    print(f"Alice has {len(friends)} friend(s)");
    root spawn Greeter();
}
