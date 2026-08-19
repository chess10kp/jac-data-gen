obj Animal {
    has name: str;

    def speak() -> str abs;
}

obj Dog(Animal) {
    has breed: str = "Unknown";

    override def speak() -> str {
        return "Woof!";
    }
}

obj Cat(Animal) {
    override def speak() -> str {
        return "Meow!";
    }
}

with entry {
    dog = Dog(name="Buddy", breed="Labrador");
    cat = Cat(name="Whiskers");

    print(f"{dog.name} says {dog.speak()}");
    print(f"{cat.name} says {cat.speak()}");
}
