obj Student {
    has name: str;
    has grades: list = [];

    def add_grade(grade: int) {
        self.grades.append(grade);
    }

    def average -> float {
        if len(self.grades) == 0 {
            return 0.0;
        }
        return sum(self.grades) / len(self.grades);
    }
}

with entry {
    student = Student(name="Alice");
    student.add_grade(90);
    student.add_grade(85);
    student.add_grade(92);

    print(f"{student.name}'s average: {student.average()}");
}
