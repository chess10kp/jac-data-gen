node Player { has name: str; has score: int; has rated: bool = False; }

walker Roster {
    has cutoff: int;
    has keep: list = [];
    can rate with Player entry {
        if not here.rated {
            here.rated = True;
            if here.score >= self.cutoff { self.keep.append(here.name); }
            visit [-->];
        }
    }
}

def names_passing(spec: dict) -> list {
    adj: dict = spec["adj"]; scores: dict = spec["scores"];
    roster_names: list = list(adj.keys());
    for group in adj.values() { for g in group { if g not in roster_names { roster_names.append(g); } } }
    team: dict = {};
    for nm in roster_names { team[nm] = Player(name=nm, score=scores[nm]); }
    for (src, group) in adj.items() { for g in group { team[src] ++> team[g]; } }
    w = team[spec["start"]] spawn Roster(cutoff=spec["cutoff"]);
    return sorted(w.keep);
}

with entry {
    print(names_passing({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': [], 'd': []}, 'scores': {'a': 80, 'b': 45, 'c': 60, 'd': 91}, 'start': 'a', 'cutoff': 60}));
}
