obj Animal {
    has name: str;
    has age: int;

    def speak {
        print(f"{self.name} makes a sound");
    }
}

obj Dog(Animal) {
    has breed: str;

    def speak {
        print(f"{self.name} barks: Woof!");
    }
}
