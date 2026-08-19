enum Color {
    RED = "red",
    GREEN = "green",
    BLUE = "blue"
}

obj Animal {
    has name: str,
        sound: str;
    def speak() -> str {
        return f"{self.name} says {self.sound}!";
    }
}
