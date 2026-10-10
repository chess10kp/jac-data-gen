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

    can count_me with SectionCheck entry {
        if self.active and self.rehearsals >= 2 {
            visitor.seen.append(self.part);
        }
    }
}

def enrol(name: str, part: Part, rehearsals: int) -> Singer {
    return root ++> Singer(name=name, part=part, rehearsals=rehearsals);
}

walker SectionCheck {
    has minimum: int;
    has seen: list[Part] = [];
    has short: list[str] = [];

    can start with Root entry {
        visit [-->[?:Singer]];
    }

    can finish with Root exit {
        result: dict[str, int] = {};
        for p in Part {
            n = len([x for x in self.seen if x == p]);
            result[p.name] = n;
            if n < self.minimum {
                self.short.append(p.name);
            }
        }
        report result;
    }
}
