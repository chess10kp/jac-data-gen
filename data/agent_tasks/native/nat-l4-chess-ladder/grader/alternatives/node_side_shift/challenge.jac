import from ladder { Player }
import from matches { Played, MatchResult }

"""Visits every player; each player shifts itself when a win reshuffles the ladder."""
walker RecordMatch {
    has challenger: str;
    has defender: str;
    has challenger_won: bool;
    has round: int;
    has lo: int = 0;
    has hi: int = 0;
    has winner: Player | None = None;

    can record with Root entry {
        cs = [p for p in [-->[?:Player]] if p.name == self.challenger];
        ds = [p for p in [-->[?:Player]] if p.name == self.defender];
        if len(cs) == 0 or len(ds) == 0 {
            report MatchResult(ok=False, reason="unknown player");
            disengage;
        }
        c = cs[0];
        d = ds[0];
        if not (d.rank < c.rank and c.rank - d.rank <= 3) {
            report MatchResult(ok=False, reason="out of range");
            disengage;
        }
        c +>:Played(challenger_won=self.challenger_won, round=self.round):+> d;
        if not self.challenger_won {
            report MatchResult(ok=True, new_rank=c.rank);
            disengage;
        }
        self.lo = d.rank;
        self.hi = c.rank;
        self.winner = c;
        visit [-->[?:Player]];
    }

    can shift with Player entry {
        if here == self.winner {
            here.rank = self.lo;
        } elif self.lo <= here.rank and here.rank < self.hi {
            here.rank = here.rank + 1;
        }
    }

    can done with Root exit {
        w = self.winner;
        if w is not None {
            report MatchResult(ok=True, new_rank=w.rank);
        }
    }
}

walker Standings {
    has order: dict[int, str] = {};

    can start with Root entry {
        visit [-->[?:Player]];
    }

    can note with Player entry {
        self.order[here.rank] = here.name;
    }

    can finish with Root exit {
        report [self.order[r] for r in range(1, len(self.order) + 1)];
    }
}

walker HeadToHead {
    has a: str;
    has b: str;

    can tally with Root entry {
        score = {self.a: 0, self.b: 0};
        for p in [-->[?:Player]] {
            if p.name != self.a and p.name != self.b {
                continue;
            }
            other = self.b if p.name == self.a else self.a;
            for opp in [p ->:Played:->] {
                if opp.name == other {
                    for m in [edge p ->:Played:-> opp] {
                        if m.challenger_won {
                            score[p.name] += 1;
                        } else {
                            score[other] += 1;
                        }
                    }
                }
            }
        }
        report score;
    }
}
