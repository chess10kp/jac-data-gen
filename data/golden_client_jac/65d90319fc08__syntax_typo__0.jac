obj Animal {
    has name: str,
        sound: str;

    def speak -> str {
        return f"{self.name} says {self.sound}!";
    }
}

with entry {
    dog = Animal(name="Rex", sound="Woof");
    print(dog.speak());  # Rex says Woof!
}
