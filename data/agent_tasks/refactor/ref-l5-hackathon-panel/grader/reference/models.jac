"""Judging graph model.

root --> Track -Entered-> Team
root --> Judge -Covers-> Track
Judge -Scored(criterion, points)-> Team
"""

enum Criterion {
    IMPACT = "impact",
    CRAFT = "craft",
    DEMO = "demo"
}

node Team {
    has name: str;

    def average -> float;
}

node Track {
    has name: str;
}

node Judge {
    has name: str;

    def covers(t: Team) -> bool;
    def sheet_for(t: Team) -> list[Scored];
}

edge Entered: Track --> Team {}

edge Covers: Judge --> Track {}

edge Scored: Judge --> Team {
    has criterion: Criterion;
    has points: int;
}

def criterion_named(name: str) -> Criterion | None;
