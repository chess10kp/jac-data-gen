obj Animal {
    has name: str;
    has sound: str;

    def speak() -> str {
        return f"{self.name} says {self.sound}!";
    }
}

with entry {
    dog = Animal(name="Rex", sound="Woof");
    print(dog.speak());
}
