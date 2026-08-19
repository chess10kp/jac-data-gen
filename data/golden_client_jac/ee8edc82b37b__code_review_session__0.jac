obj Animal {
    has name: str;

    def speak() -> str {
        return "...";
    }
}

obj Dog(Animal) {
    def speak() -> str {
        return f"{self.name} says Woof!";
    }
}

obj Cat(Animal) {
    def speak() -> str {
        return f"{self.name} says Meow!";
    }
}

with entry {
    animals: list[Animal] = [
        Dog(name="Rex"),
        Cat(name="Whiskers"),
        Dog(name="Buddy")
    ];

    for animal in animals {
        print(animal.speak());
    }
}
