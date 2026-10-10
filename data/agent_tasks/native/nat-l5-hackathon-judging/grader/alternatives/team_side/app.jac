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

    can rate with leaderboard entry {
        per_judge: dict[str, int] = {};
        for j in [self <-:Scored:<-] {
            per_judge[j.name] = sum([e.points for e in [edge j ->:Scored:-> self]]);
        }
        n = len(per_judge);
        avg = 0.0;
        if n > 0 {
            avg = round(sum(per_judge.values()) / n, 2);
        }
        visitor.rows.append({"team": self.name, "score": avg, "judges": n});
    }
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

"""Team-side abilities: each team rates itself when a leaderboard walker arrives."""
walker:pub leaderboard {
    has track: str = "";
    has rows: list[dict[str, any]] = [];

    can start with Root entry {
        if self.track == "" {
            visit [-->[?:Team]];
        } else {
            visit [-->[?:Team, track == self.track]];
        }
    }

    can finish with Root exit {
        self.rows.sort(key=lambda (r: dict[str, any]) { r["team"]; });
        self.rows.sort(key=lambda (r: dict[str, any]) { r["score"]; }, reverse=True);
        report self.rows;
    }
}

walker:pub score_team {
    has judge: str;
    has team: str;
    has criterion: str;
    has points: int;

    can score with Root entry {
        js = [j for j in [-->[?:Judge]] if j.name == self.judge];
        ts = [t for t in [-->[?:Team]] if t.name == self.team];
        reason = "";
        if not js {
            reason = "unknown judge";
        } elif not ts {
            reason = "unknown team";
        } elif self.criterion not in ["IMPACT", "CRAFT", "DEMO"] {
            reason = "bad criterion";
        } elif not (1 <= self.points <= 10) {
            reason = "bad points";
        }
        if reason {
            report {"ok": False, "reason": reason};
            disengage;
        }
        j = js[0];
        t = ts[0];
        for e in [edge j ->:Scored:-> t] {
            if e.criterion == self.criterion {
                del e;
            }
        }
        j +>:Scored(criterion=self.criterion, points=self.points):+> t;
        report {"ok": True};
    }
}

walker:pub judge_progress {
    has judge: str;

    can start with Root entry {
        missing: list[str] = [];
        for j in [-->[?:Judge]] {
            if j.name != self.judge {
                continue;
            }
            for t in [-->[?:Team]] {
                seen: list[str] = [];
                for e in [edge j ->:Scored:-> t] {
                    if e.criterion not in seen {
                        seen.append(e.criterion);
                    }
                }
                if len(seen) != 3 {
                    missing.append(t.name);
                }
            }
        }
        missing.sort();
        report missing;
    }
}
