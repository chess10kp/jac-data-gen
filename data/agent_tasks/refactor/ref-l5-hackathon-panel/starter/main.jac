"""Hackathon judging panel.

Teams enter one track; judges are assigned to tracks and may only score teams
in those tracks. Each judge gives 1-10 points per criterion (impact, craft,
demo); rescoring a criterion replaces the earlier points. A team's score is the
total of all its points divided by the number of judges who scored it.
"""

node Event {
    has teams: dict[str, str] = {};
    has judges: dict[str, list[str]] = {};
    has sheets: dict[str, dict[str, int]] = {};
}

def _event() -> Event {
    for n in [root -->] {
        if isinstance(n, Event) {
            return n;
        }
    }
    e = Event();
    root ++> e;
    return e;
}

def _key(judge: str, team: str) -> str {
    return judge + "|" + team;
}

def register_team(name: str, track: str) -> bool {
    ev = _event();
    if name in ev.teams {
        return False;
    }
    ev.teams[name] = track;
    return True;
}

def add_judge(name: str) -> bool {
    ev = _event();
    if name in ev.judges {
        return False;
    }
    ev.judges[name] = [];
    return True;
}

def assign(judge: str, track: str) -> bool {
    ev = _event();
    if judge not in ev.judges or track not in ev.teams.values() {
        return False;
    }
    if track not in ev.judges[judge] {
        ev.judges[judge].append(track);
    }
    return True;
}

def score(judge: str, team: str, criterion: str, points: int) -> str {
    ev = _event();
    if judge not in ev.judges {
        return "unknown judge";
    }
    if team not in ev.teams {
        return "unknown team";
    }
    if ev.teams[team] not in ev.judges[judge] {
        return "not assigned";
    }
    if criterion not in ["impact", "craft", "demo"] {
        return "bad criterion";
    }
    if points < 1 or points > 10 {
        return "bad points";
    }
    k = _key(judge, team);
    if k not in ev.sheets {
        ev.sheets[k] = {};
    }
    ev.sheets[k][criterion] = points;
    return "ok";
}

def team_score(team: str) -> float {
    ev = _event();
    total = 0;
    judges = 0;
    for j in ev.judges {
        k = _key(j, team);
        if k in ev.sheets and len(ev.sheets[k]) > 0 {
            judges += 1;
            for c in ev.sheets[k] {
                total += ev.sheets[k][c];
            }
        }
    }
    if judges == 0 {
        return 0.0;
    }
    return round(total / judges, 2);
}

def leaderboard(track: str) -> list[str] {
    ev = _event();
    names: list[str] = [];
    for t in ev.teams {
        if track == "" or ev.teams[t] == track {
            names.append(t);
        }
    }
    return sorted(names, key=lambda (n: str) { (-team_score(n), n); });
}

def pending(judge: str) -> list[str] {
    ev = _event();
    if judge not in ev.judges {
        return [];
    }
    out: list[str] = [];
    for t in ev.teams {
        if ev.teams[t] not in ev.judges[judge] {
            continue;
        }
        k = _key(judge, t);
        done = 0;
        if k in ev.sheets {
            done = len(ev.sheets[k]);
        }
        if done < 3 {
            out.append(t);
        }
    }
    return sorted(out);
}
