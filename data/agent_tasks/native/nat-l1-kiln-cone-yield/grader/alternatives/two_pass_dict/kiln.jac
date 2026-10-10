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
    has loaded: dict[int, int] = {};
    has lost: dict[int, int] = {};

    can start with Root entry {
        visit [-->[?:Firing, aborted == False, pieces > 0]];
    }

    can tally with Firing entry {
        self.loaded[here.cone] = self.loaded.get(here.cone, 0) + here.pieces;
        self.lost[here.cone] = self.lost.get(here.cone, 0) + here.cracked + here.glaze_faults;
    }

    can finish with Root exit {
        report [
            ConeStat(
                cone=c,
                pieces=self.loaded[c],
                losses=self.lost[c],
                yield_pct=(self.loaded[c] - self.lost[c]) * 100 // self.loaded[c]
            )
            for c in sorted(self.loaded)
        ];
    }
}
