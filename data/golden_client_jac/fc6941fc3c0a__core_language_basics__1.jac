class Animal {

    # __init__ works here too
    def init(self: Animal, name: str, sound: str) {
        self.name = name;
        self.sound = sound;
    }

    def speak(self: Animal) -> str {
        return f"{self.name} says {self.sound}!";
    }
}

with entry {
    dog = Animal("Rex", "Woof");
    print(dog.speak());  # Rex says Woof!
}
