obj Animal {
    has name: str;
    def speak() -> str;
}

impl Animal.speak() -> str {
    return "...";
}

obj Dog(Animal) {
    has breed: str = "Unknown";
    def speak() -> str;
}

impl Dog.speak() -> str {
    return "Woof!";
}

obj Cat(Animal) {
    def speak() -> str;
}

impl Cat.speak() -> str {
    return "Meow!";
}

with entry {
    dog = Dog(name="Buddy", breed="Labrador");
    cat = Cat(name="Whiskers");
    print(f"{dog.name} says {dog.speak()}");
    print(f"{cat.name} says {cat.speak()}");
}
