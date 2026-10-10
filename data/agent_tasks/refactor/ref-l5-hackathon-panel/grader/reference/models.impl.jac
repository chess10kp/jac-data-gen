impl criterion_named(name: str) -> Criterion | None {
    for c in Criterion {
        if c.value == name {
            return c;
        }
    }
    return None;
}

impl Team.average -> float {
    judges = [self <-:Scored:<-];
    if not judges {
        return 0.0;
    }
    total = sum([e.points for e in [edge self <-:Scored:<-]]);
    return round(total / len(judges), 2);
}

impl Judge.covers(t: Team) -> bool {
    mine = [self ->:Covers:->];
    return any([tr in mine for tr in [t <-:Entered:<-]]);
}

impl Judge.sheet_for(t: Team) -> list[Scored] {
    return [edge self ->:Scored:-> t];
}
