impl find_team(name: str) -> Team | None {
    wanted = name;
    found = [root -->[?:Track] ->:Entered:->[?:Team, name == wanted]];
    return found[0] if found else None;
}

impl find_judge(name: str) -> Judge | None {
    wanted = name;
    found = [root -->[?:Judge, name == wanted]];
    return found[0] if found else None;
}

impl find_track(name: str) -> Track | None {
    wanted = name;
    found = [root -->[?:Track, name == wanted]];
    return found[0] if found else None;
}

impl register_team(name: str, track: str) -> bool {
    if find_team(name) is not None {
        return False;
    }
    tr = find_track(track);
    if tr is None {
        tr = root ++> Track(name=track);
    }
    tr +>:Entered():+> Team(name=name);
    return True;
}

impl add_judge(name: str) -> bool {
    if find_judge(name) is not None {
        return False;
    }
    root ++> Judge(name=name);
    return True;
}

impl assign(judge: str, track: str) -> bool {
    j = find_judge(judge);
    tr = find_track(track);
    if j is None or tr is None {
        return False;
    }
    if tr not in [j ->:Covers:->] {
        j +>:Covers():+> tr;
    }
    return True;
}

impl score(judge: str, team: str, criterion: str, points: int) -> str {
    j = find_judge(judge);
    if j is None {
        return "unknown judge";
    }
    t = find_team(team);
    if t is None {
        return "unknown team";
    }
    if not j.covers(t) {
        return "not assigned";
    }
    c = criterion_named(criterion);
    if c is None {
        return "bad criterion";
    }
    if points < 1 or points > 10 {
        return "bad points";
    }
    existing = [e for e in j.sheet_for(t) if e.criterion == c];
    if existing {
        existing[0].points = points;
    } else {
        j +>:Scored(criterion=c, points=points):+> t;
    }
    return "ok";
}

impl team_score(team: str) -> float {
    t = find_team(team);
    return t.average() if t is not None else 0.0;
}

impl leaderboard(track: str) -> list[str] {
    w = root spawn Standings(track=track);
    ranked = sorted(w.teams, key=lambda (t: Team) { (-t.average(), t.name); });
    return [t.name for t in ranked];
}

impl pending(judge: str) -> list[str] {
    j = find_judge(judge);
    if j is None {
        return [];
    }
    return sorted((j spawn Backlog()).todo);
}
