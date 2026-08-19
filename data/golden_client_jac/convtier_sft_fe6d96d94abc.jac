obj Gradebook {
    has grades: list[float] = [];

    def add(g: float) -> None { self.grades.append(g); }

    def average() -> float { return sum(self.grades) / len(self.grades); }
}

with entry {
    gb = Gradebook();
    gb.add(80.0);
    gb.add(90.0);
    gb.add(100.0);
    print(gb.average());
}
