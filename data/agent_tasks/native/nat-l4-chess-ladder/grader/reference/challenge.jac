"""Ladder challenges: record matches, update ranks, read the ladder."""
import from ladder { Player, player }
import from matches { Played, MatchResult }

walker RecordMatch {
    has challenger: str;
    has defender: str;
    has challenger_won: bool;
    has round: int;

    can record with Root entry {
        c = player(self.challenger);
        d = player(self.defender);
        if c is None or d is None {
            report MatchResult(ok=False, reason="unknown player");
            return;
        }
        gap = c.rank - d.rank;
        if gap <= 0 or gap > 3 {
            report MatchResult(ok=False, reason="out of range");
            return;
        }
        c +>:Played(challenger_won=self.challenger_won, round=self.round):+> d;
        if self.challenger_won {
            old_c = c.rank;
            old_d = d.rank;
            for p in [root -->[?:Player]] {
                if p.rank >= old_d and p.rank < old_c {
                    p.rank += 1;
                }
            }
            c.rank = old_d;
        }
        report MatchResult(ok=True, new_rank=c.rank);
    }
}

walker Standings {
    can list with Root entry {
        report [p.name for p in sorted([root -->[?:Player]], key=lambda (p: Player) { p.rank; })];
    }
}

walker HeadToHead {
    has a: str;
    has b: str;

    can tally with Root entry {
        pa = player(self.a);
        pb = player(self.b);
        wins = {self.a: 0, self.b: 0};
        if pa is not None and pb is not None {
            for m in [edge pa ->:Played:-> pb] {
                wins[self.a if m.challenger_won else self.b] += 1;
            }
            for m in [edge pb ->:Played:-> pa] {
                wins[self.b if m.challenger_won else self.a] += 1;
            }
        }
        report wins;
    }
}
