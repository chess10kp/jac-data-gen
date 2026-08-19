obj Animal {
    has name: str,
        sound: str = "...";

    def speak() -> str {
        return f"{self.name} says {self.sound}";
    }
}

obj Dog(Animal) {
    has sound: str = "woof";
}

with entry {
    a = Animal(name="Rex");
    print(a.speak());         # Rex says ...
    d = Dog(name="Rex");
    print(d.speak());         # Rex says woof
}
