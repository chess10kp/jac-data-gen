obj Student {
    has name: str;
    has grades: list = [];

    def add_grade(grade: int) {
        self.grades.append(grade);
    }

    def average -> float {
        return sum(self.grades) / len(self.grades);
    }
}
