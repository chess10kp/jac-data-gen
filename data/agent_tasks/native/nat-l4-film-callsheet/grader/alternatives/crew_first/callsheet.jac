import from crew { Crew, prep_minutes }
import from schedule { ShootDay, Scene }

"""Crew-centric variant: look at each crew member's scenes on the day."""
walker CallSheet {
    has day: int;
    has locations: int = 0;

    can build with Root entry {
        days = [d for d in [-->[?:ShootDay]] if d.day == self.day];
        todays: list[Scene] = [];
        for d in days {
            todays.extend([d -->[?:Scene]]);
        }
        self.locations = len({s.location for s in todays});
        entries: list[tuple[int, str]] = [];
        for c in [-->[?:Crew]] {
            mine = [s.start_min for s in [c -->[?:Scene]] if s in todays];
            if mine {
                t = min(mine) - prep_minutes(c.dept);
                hh = str(t // 60).zfill(2);
                mm = str(t % 60).zfill(2);
                entries.append((t, c.name + "|" + hh + ":" + mm + " " + c.name + " (" + c.dept.name + ")"));
            }
        }
        entries.sort();
        report [e[1].split("|")[1] for e in entries];
    }
}
