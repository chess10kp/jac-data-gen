"""Grading run: typed reports declared right on the walker.

Declaring `has reports: list[int]` makes every `report` statement
type-checked, so a stray string score fails at compile time instead
of polluting results. The grader collects scores and the entry block
prints the class average.
"""

node Quiz {
    has student: str = "";
    has score: int = 0;
}

walker Grader {
    # Typed reports: only int values may be reported from this walker.
    has reports: list[int] = [];
    has graded: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can grade with Quiz entry {
        report here.score;
        self.graded += 1;
        visit [-->];
    }
}

with entry {
    root ++> Quiz(student="Ana", score=92)
        ++> Quiz(student="Ben", score=78)
        ++> Quiz(student="Chloe", score=88)
        ++> Quiz(student="Dev", score=95);

    result = root spawn Grader();
    total = sum(result.reports);
    average = total / len(result.reports) if result.reports else 0;
    print(f"Graded {result.reports}");
    print(f"Class average: {average:.1f}");
}
