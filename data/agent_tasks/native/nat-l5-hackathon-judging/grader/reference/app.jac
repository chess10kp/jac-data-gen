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

def named_judge(name: str) -> Judge | None {
    for j in [root -->[?:Judge]] {
        if j.name == name {
            return j;
        }
    }
    return None;
}

def named_team(name: str) -> Team | None {
    for t in [root -->[?:Team]] {
        if t.name == name {
            return t;
        }
    }
    return None;
}

walker:pub score_team {
    has judge: str;
    has team: str;
    has criterion: str;
    has points: int;

    can score with Root entry {
        j = named_judge(self.judge);
        if j is None {
            report {"ok": False, "reason": "unknown judge"};
            return;
        }
        t = named_team(self.team);
        if t is None {
            report {"ok": False, "reason": "unknown team"};
            return;
        }
        if self.criterion not in [c.name for c in Criterion] {
            report {"ok": False, "reason": "bad criterion"};
            return;
        }
        if self.points < 1 or self.points > 10 {
            report {"ok": False, "reason": "bad points"};
            return;
        }
        existing = [e for e in [edge j ->:Scored:-> t] if e.criterion == self.criterion];
        if existing {
            existing[0].points = self.points;
        } else {
            j +>:Scored(criterion=self.criterion, points=self.points):+> t;
        }
        report {"ok": True};
    }
}

walker:pub leaderboard {
    has track: str = "";
    has rows: list[dict[str, any]] = [];

    can start with Root entry {
        visit [-->[?:Team]];
    }

    can rate with Team entry {
        if self.track and here.track != self.track {
            return;
        }
        judges = [here <-:Scored:<-];
        total = 0;
        for j in judges {
            for e in [edge j ->:Scored:-> here] {
                total += e.points;
            }
        }
        score = round(total / len(judges), 2) if judges else 0.0;
        self.rows.append({"team": here.name, "score": score, "judges": len(judges)});
    }

    can finish with Root exit {
        report sorted(self.rows, key=lambda (r: dict[str, any]) { (-r["score"], r["team"]); });
    }
}

walker:pub judge_progress {
    has judge: str;
    has todo: list[str] = [];
    has me: Judge | None = None;

    can start with Root entry {
        self.me = named_judge(self.judge);
        if self.me is not None {
            visit [-->[?:Team]];
        }
    }

    can check with Team entry {
        j = self.me;
        if j is None {
            return;
        }
        done = {e.criterion for e in [edge j ->:Scored:-> here]};
        if len(done) < 3 {
            self.todo.append(here.name);
        }
    }

    can finish with Root exit {
        report sorted(self.todo);
    }
}
