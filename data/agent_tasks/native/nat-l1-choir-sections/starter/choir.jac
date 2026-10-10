"""Community choir roster: one Singer node per member, attached to root."""

enum Part {
    SOPRANO,
    ALTO,
    TENOR,
    BASS
}

node Singer {
    has name: str;
    has part: Part;
    has active: bool = True;
    has rehearsals: int = 0;   # attended in the current rehearsal cycle
}

def enrol(name: str, part: Part, rehearsals: int) -> Singer {
    return root ++> Singer(name=name, part=part, rehearsals=rehearsals);
}
