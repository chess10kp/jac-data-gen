"""Lifting journal: sets per exercise per session date, with estimated one-rep maxes."""

enum SetKind {
    WARMUP = "warmup",
    WORK = "work",
    FAIL = "fail"
}

node Exercise {
    has name: str;
}

node Session {
    has date: str;
}

"""Everything one exercise contributed to one session."""
edge Trained: Exercise --> Session {
    has volume: float = 0.0;
    has top: float = 0.0;
    has fails: int = 0;
}

def kind_of(label: str) -> SetKind | None {
    kinds: list[SetKind] = [SetKind.WARMUP, SetKind.WORK, SetKind.FAIL];
    for k in kinds {
        if k.value == label {
            return k;
        }
    }
    return None;
}

"""Walk the sessions of one exercise and fold the per-session stats."""
walker History {
    has since: str = "";
    has ex: Exercise | None = None;
    has top: float = 0.0;
    has when: str = "";
    has volume: float = 0.0;
    has fails: int = 0;

    can start with Exercise entry {
        self.ex = here;
        visit [here ->:Trained:->];
    }

    can read with Session entry {
        link = [edge self.ex ->:Trained:-> here][0];
        self.fails += link.fails;
        if here.date >= self.since {
            self.volume += link.volume;
        }
        if link.top > self.top or (link.top == self.top and link.top > 0 and here.date < self.when) {
            self.top = link.top;
            self.when = here.date;
        }
    }
}

node Journal {
    has athlete: str;

    def exercise(name: str) -> Exercise | None {
        wanted = name.lower();
        found = [self -->[?:Exercise, name == wanted]];
        return found[0] if found else None;
    }

    def session(date: str) -> Session {
        wanted = date;
        found = [self -->[?:Session, date == wanted]];
        return found[0] if found else self ++> Session(date=date);
    }

    def history(exercise: str, since: str) -> History {
        ex = self.exercise(exercise);
        if ex is None {
            return History(since=since);
        }
        return ex spawn History(since=since);
    }

    def log_set(exercise: str, date: str, weight: float, reps: int, kind: str) -> bool {
        k = kind_of(kind);
        if k is None or reps <= 0 {
            return False;
        }
        ex = self.exercise(exercise);
        if ex is None {
            ex = self ++> Exercise(name=exercise.lower());
        }
        s = self.session(date);
        links = [edge ex ->:Trained:-> s];
        link = links[0] if links else None;
        if link is None {
            ex +>:Trained():+> s;
            link = [edge ex ->:Trained:-> s][0];
        }
        if k == SetKind.FAIL {
            link.fails += 1;
        }
        if k != SetKind.WARMUP {
            link.volume += weight * reps;
        }
        if k == SetKind.WORK {
            link.top = max(link.top, round(weight * (1 + reps / 30), 1));
        }
        return True;
    }

    def exercises() -> list[str] {
        return sorted([e.name for e in [self -->[?:Exercise]]]);
    }

    def best(exercise: str) -> float {
        return self.history(exercise, "").top;
    }

    def best_date(exercise: str) -> str {
        return self.history(exercise, "").when;
    }

    def volume(exercise: str, since: str) -> float {
        return self.history(exercise, since).volume;
    }

    def failures(exercise: str) -> int {
        return self.history(exercise, "").fails;
    }

    def trained_on(date: str) -> list[str] {
        wanted = date;
        days = [self -->[?:Session, date == wanted]];
        if not days {
            return [];
        }
        return sorted([e.name for e in [days[0] <-:Trained:<-]]);
    }
}
