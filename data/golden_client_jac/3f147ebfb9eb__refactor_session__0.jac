node Person {
    has name: str;
    has age: int;
}
walker AgeCollector {
    can start with Root entry;
    can collect with Person entry;
}
impl AgeCollector.start {
    visit [-->];
}
impl AgeCollector.collect {
    report here.age;
    visit [-->];
}
with entry {
    alice = Person(name="Alice", age=25);
    bob = Person(name="Bob", age=30);
    charlie = Person(name="Charlie", age=28);
    root ++> alice ++> bob ++> charlie;
    ages = root spawn AgeCollector();
    print(f"Collected ages: {ages.reports}");
}
