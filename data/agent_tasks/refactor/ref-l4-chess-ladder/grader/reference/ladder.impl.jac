"""Implementations for ladder.jac."""

impl RecordChallenge.record {
    c = find_player(self.challenger);
    d = find_player(self.defender);
    if c is None or d is None or self.challenger == self.defender {
        self.result = "unknown player";
        return;
    }
    gap = c.rank - d.rank;
    if gap <= 0 or gap > 3 {
        self.result = "out of range";
        return;
    }
    c +>:Played(outcome=self.outcome, round=self.round):+> d;
    if self.outcome == Outcome.WIN {
        old_c = c.rank;
        old_d = d.rank;
        for p in [root -->[?:Player]] {
            if p.rank >= old_d and p.rank < old_c {
                p.rank += 1;
            }
        }
        c.rank = old_d;
    }
    self.result = "ok";
}

impl Tally.add(o: Outcome, as_challenger: bool) {
    if o == Outcome.DRAW {
        self.draws += 1;
    } elif (o == Outcome.WIN) == as_challenger {
        self.wins += 1;
    } else {
        self.losses += 1;
    }
}

impl Tally.count {
    for opp in [here ->:Played:->] {
        if self.against == "" or opp.name == self.against {
            for m in [edge here ->:Played:-> opp] {
                self.add(m.outcome, True);
            }
        }
    }
    for opp in [here <-:Played:<-] {
        if self.against == "" or opp.name == self.against {
            for m in [edge opp ->:Played:-> here] {
                self.add(m.outcome, False);
            }
        }
    }
}

impl Activity.start {
    visit [-->[?:Player]];
}

impl Activity.check {
    since = self.since;
    if [here ->:Played:round >= since:->] or [here <-:Played:round >= since:<-] {
        self.names.append(here.name);
    }
}

impl find_player(name: str) -> Player | None {
    wanted = name;
    found = [root -->[?:Player, name == wanted]];
    return found[0] if found else None;
}

impl join(name: str) -> int {
    if find_player(name) is not None {
        return 0;
    }
    rank = len([root -->[?:Player]]) + 1;
    root ++> Player(name=name, rank=rank);
    return rank;
}

impl standings -> list[str] {
    return [p.name for p in sorted([root -->[?:Player]], key=lambda (p: Player) -> int { return p.rank; })];
}

impl challenge(challenger: str, defender: str, outcome: str, round: int) -> str {
    if outcome not in [o.value for o in Outcome] {
        if find_player(challenger) is None or find_player(defender) is None or challenger == defender {
            return "unknown player";
        }
        return "bad outcome";
    }
    w = root spawn RecordChallenge(
        challenger=challenger, defender=defender, outcome=Outcome(outcome), round=round
    );
    return w.result;
}

impl record(name: str) -> list[int] {
    p = find_player(name);
    if p is None {
        return [0, 0, 0];
    }
    t = p spawn Tally();
    return [t.wins, t.losses, t.draws];
}

impl head_to_head(a: str, b: str) -> list[int] {
    pa = find_player(a);
    if pa is None {
        return [0, 0, 0];
    }
    t = pa spawn Tally(against=b);
    return [t.wins, t.losses, t.draws];
}

impl withdraw(name: str) -> bool {
    p = find_player(name);
    if p is None {
        return False;
    }
    gone = p.rank;
    del p;
    for q in [root -->[?:Player]] {
        if q.rank > gone {
            q.rank -= 1;
        }
    }
    return True;
}

impl active_since(round: int) -> list[str] {
    w = root spawn Activity(since=round);
    return sorted(w.names);
}
