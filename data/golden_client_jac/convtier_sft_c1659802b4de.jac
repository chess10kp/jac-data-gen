obj Student {
    has name: str = "";
    has scores: list = [];

    def average -> float {
        return round(sum(self.scores) / len(self.scores), 1);
    }

    def letter -> str {
        avg = self.average();
        if avg >= 90 {
            return "A";
        } elif avg >= 80 {
            return "B";
        } elif avg >= 70 {
            return "C";
        }
        return "F";
    }

    def report -> str {
        return f"{self.name}: {self.average()} ({self.letter()})";
    }
}

def grade_report(rec: dict) -> str {
    return Student(name=rec["name"], scores=rec["scores"]).report();
}

with entry {
    print(grade_report({'name': 'Ann', 'scores': [90, 85, 88]}));
}
