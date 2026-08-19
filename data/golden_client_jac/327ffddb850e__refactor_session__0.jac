obj Animal {
    has name: str;
    has sound: str = "...";
    static def named(name: str) -> Animal;
    def speak() -> str;
}
impl Animal.named {
    return Animal(name=name);
}
impl Animal.speak {
    return f"{self.name} says {self.sound}";
}
obj Dog(Animal) {
    has sound: str = "woof";
}
with entry {
    a = Animal.named("Rex");
    print(a.speak());
    d = Dog(name="Rex");
    print(d.speak());
}
