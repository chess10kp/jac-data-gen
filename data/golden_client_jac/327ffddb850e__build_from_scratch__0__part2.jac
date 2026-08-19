obj Animal {
    has name: str,
        sound: str = "...";

    static def named(name: str) -> Animal {
        return Animal(name=name);
    }

    def speak() -> str {
        return f"{self.name} says {self.sound}";
    }
}

obj Dog(Animal) {
    has sound: str = "woof";
}

with entry {
    a = Animal.named("Rex");
    print(a.speak());         # Rex says ...
    d = Dog(name="Rex");
    print(d.speak());         # Rex says woof
}
