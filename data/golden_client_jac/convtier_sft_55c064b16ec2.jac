obj Temperature {
    has celsius: float;

    def to_kelvin() -> float { return self.celsius + 273.15; }
}

with entry {
    t = Temperature(celsius=0.0);
    print(t.to_kelvin());
}
