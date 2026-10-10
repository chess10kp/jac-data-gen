"""Hackathon judging service.

root --> Team, root --> Judge, Judge -Scored(criterion, points)-> Team
"""

enum Criterion {
    IMPACT,
    CRAFT,
    DEMO
}

node Team {
    has name: str;
    has track: str;
}

node Judge {
    has name: str;
}

edge Scored: Judge --> Team {
    has criterion: str;   # a Criterion name, e.g. "CRAFT"
    has points: int;
}

def:pub register_team(name: str, track: str) -> Team {
    return root ++> Team(name=name, track=track);
}

def:pub add_judge(name: str) -> Judge {
    return root ++> Judge(name=name);
}
