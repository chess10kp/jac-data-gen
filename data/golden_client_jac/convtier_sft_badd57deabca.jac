obj Temperature {
    has celsius: float;

    def to_fahrenheit() -> float {
        return self.celsius * 9 / 5 + 32;
    }
}

with entry {
    t = Temperature(celsius=100.0);
    print(t.to_fahrenheit());
}
