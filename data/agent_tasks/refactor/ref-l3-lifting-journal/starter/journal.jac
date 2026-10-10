"""Lifting journal: sets per exercise per session date, with estimated one-rep maxes."""

obj Journal {
    has athlete: str;
    has kinds: list[str] = ["warmup", "work", "fail"];
    has sets: dict[str, list[dict[str, any]]] = {};

    def log_set(exercise: str, date: str, weight: float, reps: int, kind: str) -> bool {
        if kind not in self.kinds or reps <= 0 {
            return False;
        }
        name = exercise.lower();
        if name not in self.sets {
            self.sets[name] = [];
        }
        self.sets[name].append({"date": date, "weight": weight, "reps": reps, "kind": kind});
        return True;
    }

    def exercises() -> list[str] {
        return sorted([k for k in self.sets]);
    }

    def best(exercise: str) -> float {
        top = 0.0;
        for s in self.sets.get(exercise.lower(), []) {
            if s["kind"] == "work" {
                v = round(s["weight"] * (1 + s["reps"] / 30), 1);
                if v > top {
                    top = v;
                }
            }
        }
        return top;
    }

    def best_date(exercise: str) -> str {
        top = 0.0;
        when = "";
        for s in self.sets.get(exercise.lower(), []) {
            if s["kind"] == "work" {
                v = round(s["weight"] * (1 + s["reps"] / 30), 1);
                if v > top or (v == top and s["date"] < when) {
                    top = v;
                    when = s["date"];
                }
            }
        }
        return when;
    }

    def volume(exercise: str, since: str) -> float {
        total = 0.0;
        for s in self.sets.get(exercise.lower(), []) {
            if s["kind"] != "warmup" and s["date"] >= since {
                total += s["weight"] * s["reps"];
            }
        }
        return total;
    }

    def failures(exercise: str) -> int {
        n = 0;
        for s in self.sets.get(exercise.lower(), []) {
            if s["kind"] == "fail" {
                n += 1;
            }
        }
        return n;
    }

    def trained_on(date: str) -> list[str] {
        out: list[str] = [];
        for name in self.sets {
            for s in self.sets[name] {
                if s["date"] == date and name not in out {
                    out.append(name);
                }
            }
        }
        return sorted(out);
    }
}
