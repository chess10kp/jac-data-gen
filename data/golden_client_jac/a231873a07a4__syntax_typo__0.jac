# Base object
obj Animal {
    has name: str;
    has age: int;

    def speak {
        print(f"{self.name} makes a sound");
    }
}

# Specialized object
obj Dog(Animal) {  # Dog inherits from Animal
    has breed: str;

    # Override parent method
    def speak {
        print(f"{self.name} barks: Woof!");
    }

    # New method specific to Dog
    def fetch {
        print(f"{self.name} fetches the ball!");
    }
}

obj Cat(Animal) {
    # Override parent method
    def speak {
        print(f"{self.name} meows: Meow!");
    }
}

with entry {
    dog = Dog(name="Buddy", age=3, breed="Labrador");
    cat = Cat(name="Whiskers", age=2);

    dog.speak();  # Buddy barks: Woof!
    cat.speak();  # Whiskers meows: Meow!

    dog.fetch();  # Buddy fetches the ball!
}
