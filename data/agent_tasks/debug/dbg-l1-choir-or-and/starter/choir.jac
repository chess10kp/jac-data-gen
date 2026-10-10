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

walker SectionCheck {
    has minimum: int;
    has counts: dict[str, int] = {};
    has short: list[str] = [];

    can start with Root entry {
        for p in Part {
            self.counts[p.name] = 0;
        }
        visit [-->[?:Singer]];
    }

    can tally with Singer entry {
        if here.active or here.rehearsals >= 2 {
            self.counts[here.part.name] += 1;
        }
    }

    can finish with Root exit {
        for p in Part {
            if self.counts[p.name] < self.minimum {
                self.short.append(p.name);
            }
        }
        report self.counts;
    }
}
