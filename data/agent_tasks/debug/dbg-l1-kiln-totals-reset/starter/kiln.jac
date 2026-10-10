"""Ceramics studio kiln log: one Firing node per load, on root."""

node Firing {
    has batch: str;
    has cone: int;            # pyrometric cone the load was fired to
    has pieces: int;
    has cracked: int = 0;
    has glaze_faults: int = 0;
    has aborted: bool = False;
}

obj ConeStat {
    has cone: int;
    has pieces: int;
    has losses: int;
    has yield_pct: int;
}

def log_firing(batch: str, cone: int, pieces: int, cracked: int, glaze_faults: int) -> Firing {
    return root ++> Firing(batch=batch, cone=cone, pieces=pieces, cracked=cracked, glaze_faults=glaze_faults);
}

walker ConeYield {
    has totals: dict[int, ConeStat] = {};

    can start with Root entry {
        visit [-->[?:Firing]];
    }

    can tally with Firing entry {
        if here.aborted or here.pieces == 0 {
            return;
        }
        self.totals[here.cone] = ConeStat(cone=here.cone, pieces=0, losses=0, yield_pct=0);
        stat = self.totals[here.cone];
        stat.pieces += here.pieces;
        stat.losses += here.cracked + here.glaze_faults;
    }

    can finish with Root exit {
        out: list[ConeStat] = [];
        for cone in sorted(self.totals.keys()) {
            s = self.totals[cone];
            s.yield_pct = (s.pieces - s.losses) * 100 // s.pieces;
            out.append(s);
        }
        report out;
    }
}
