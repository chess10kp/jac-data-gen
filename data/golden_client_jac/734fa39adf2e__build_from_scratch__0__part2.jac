obj Animal {
    has name: str;

    def speak() -> str {
        return "...";
    }
}

obj Dog(Animal) {
    has breed: str = "Unknown";

    def speak() -> str {
        return "Woof!";
    }
}

obj Cat(Animal) {
    def speak() -> str {
        return "Meow!";
    }
}

with entry {
    dog = Dog(name="Buddy", breed="Labrador");
    cat = Cat(name="Whiskers");

    print(f"{dog.name} says {dog.speak()}");  # Buddy says Woof!
    print(f"{cat.name} says {cat.speak()}");  # Whiskers says Meow!
}
