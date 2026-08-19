enum Color { RED = "red", GREEN = "green", BLUE = "blue" }

obj Animal {
    has name: str, sound: str;
    def speak() -> str { return f"{self.name} says {self.sound}!"; }
}

obj Dog(Animal) {
    has breed: str;
    override def speak() -> str {
        return f"{self.name} the {self.breed} says {self.sound}!";
    }
}

with entry {
    dog = Dog(name="Rex", sound="woof", breed="Labrador");
    print(dog.speak());
    print(f"Favorite color: {Color.BLUE.value}");
}
