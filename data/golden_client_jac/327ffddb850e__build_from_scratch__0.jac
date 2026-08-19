obj Animal {
    has name: str,
        sound: str = "...";
    static def named(name: str) -> Animal {
        return Animal(name=name);
    }
    def speak() -> str {
        return f"{self.name} says {self.sound}";
    }
}
