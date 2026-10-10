"""Lifting log: Exercise nodes on root, one SetEntry node per logged set."""

import sys;

node Exercise {
    has name: str;
}

node SetEntry {
    has date: str;
    has weight: float;
    has reps: int;

    def e1rm -> float {
        return round(self.weight * (1 + self.reps / 30), 1);
    }
}

def find_exercise(name: str) -> Exercise | None {
    for e in [root -->[?:Exercise]] {
        if e.name == name.lower() {
            return e;
        }
    }
    return None;
}

walker LogSet {
    has exercise: str;
    has date: str;
    has weight: float;
    has reps: int;

    can log with Root entry {
        ex = find_exercise(self.exercise);
        if ex is None {
            ex = here ++> Exercise(name=self.exercise.lower());
        }
        report ex ++> SetEntry(date=self.date, weight=float(self.weight), reps=int(self.reps));
    }
}

walker PersonalBest {
    has exercise: str;
    has best: float = 0.0;
    has best_date: str = "";

    can start with Root entry {
        ex = find_exercise(self.exercise);
        if ex is not None {
            visit [ex -->[?:SetEntry]];
        }
    }

    can weigh with SetEntry entry {
        v = here.e1rm();
        if v > self.best or (v == self.best and (self.best_date == "" or here.date < self.best_date)) {
            self.best = v;
            self.best_date = here.date;
        }
    }

    can finish with exit {
        report {"e1rm": self.best, "date": self.best_date};
    }
}

walker Volume {
    has exercise: str;
    has since: str;
    has total: float = 0.0;

    can start with Root entry {
        ex = find_exercise(self.exercise);
        if ex is not None {
            visit [ex -->[?:SetEntry]];
        }
    }

    can add with SetEntry entry {
        if here.date >= self.since {
            self.total += here.weight * here.reps;
        }
    }

    can finish with exit {
        report self.total;
    }
}

def run_cli(argv: list[str]) -> int {
    cmd = argv[0] if argv else "";
    if cmd == "log" and len(argv) == 5 {
        root spawn LogSet(exercise=argv[1], date=argv[2], weight=float(argv[3]), reps=int(argv[4]));
        print(f"logged {argv[1].lower()} {argv[3]}x{argv[4]}");
    } elif cmd == "best" and len(argv) == 2 {
        r = (root spawn PersonalBest(exercise=argv[1])).reports[0];
        if r["date"] {
            print(f"{argv[1].lower()} {r['e1rm']} on {r['date']}");
        } else {
            print(f"no sets for {argv[1].lower()}");
        }
    } elif cmd == "volume" and len(argv) == 3 {
        print((root spawn Volume(exercise=argv[1], since=argv[2])).reports[0]);
    } else {
        print("usage: log EX DATE KG REPS | best EX | volume EX SINCE");
        return 2;
    }
    return 0;
}

with entry:__main__ {
    sys.`exit(run_cli(sys.argv[1:]));
}
