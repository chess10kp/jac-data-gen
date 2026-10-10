"""Daily call sheet: who must be on set when."""
import from crew { Crew, Department, prep_minutes }
import from schedule { ShootDay, Scene, Scheduled, AssignedTo }

def clock(minutes: int) -> str {
    return f"{minutes // 60:02d}:{minutes % 60:02d}";
}

walker CallSheet {
    has day: int;
    has locations: int = 0;
    has first_scene: dict[str, int] = {};
    has who: dict[str, Crew] = {};
    has places: set[str] = set();

    can start with Root entry {
        visit [-->[?:ShootDay]];
    }

    can on_day with ShootDay entry {
        if here.day == self.day {
            visit [here ->:Scheduled:->];
        }
    }

    can on_scene with Scene entry {
        self.places.add(here.location);
        for c in [here <-:AssignedTo:<-] {
            key = jid(c);
            self.who[key] = c;
            if key not in self.first_scene or here.start_min < self.first_scene[key] {
                self.first_scene[key] = here.start_min;
            }
        }
    }

    can finish with Root exit {
        rows: list[tuple[int, str, str]] = [];
        for (key, start) in self.first_scene.items() {
            c = self.who[key];
            rows.append((start - prep_minutes(c.dept), c.name, c.dept.name));
        }
        self.locations = len(self.places);
        report [f"{clock(t)} {name} ({dept})" for (t, name, dept) in sorted(rows)];
    }
}
