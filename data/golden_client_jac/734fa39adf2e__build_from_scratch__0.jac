obj Animal {
    has name: str;

    def speak() -> str {
        return "...";
    }
}

obj Dog(Animal) {
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
    dog = Dog(name="Buddy");
    cat = Cat(name="Whiskers");

    print(f"{dog.name} says {dog.speak()}");
    print(f"{cat.name} says {cat.speak()}");
}
