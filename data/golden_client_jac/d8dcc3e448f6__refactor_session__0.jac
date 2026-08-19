enum Color {
    RED = "red",
    GREEN = "green",
    BLUE = "blue"
}
obj Animal {
    has name: str;
    has sound: str;
    def speak() -> str;
}
impl Animal.speak {
    return f"{self.name} says {self.sound}!";
}
obj Dog(Animal) {
    has breed: str;
    def speak() -> str;
}
impl Dog.speak {
    return f"{self.name} the {self.breed} says {self.sound}!";
}
with entry {
    dog = Dog(name="Rex", sound="woof", breed="Labrador");
    print(dog.speak());
    print(f"Favorite color: {Color.BLUE.value}");
}
