obj Animal {
    has name: str;
    has age: int;
    def speak;
}

impl Animal.speak {
    print(f"{self.name} makes a sound");
}

obj Dog(Animal) {
    has breed: str;
    def speak;
    def fetch;
}

impl Dog.speak {
    print(f"{self.name} barks: Woof!");
}

impl Dog.fetch {
    print(f"{self.name} fetches the ball!");
}

obj Cat(Animal) {
    def speak;
}

impl Cat.speak {
    print(f"{self.name} meows: Meow!");
}

with entry {
    dog = Dog(name="Buddy", age=3, breed="Labrador");
    cat = Cat(name="Whiskers", age=2);
    dog.speak();
    cat.speak();
    dog.fetch();
}
