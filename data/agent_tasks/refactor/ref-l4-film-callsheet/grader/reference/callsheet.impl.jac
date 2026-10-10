"""Implementations for callsheet.jac."""

impl CallSheet.start {
    wanted = self.day;
    visit [-->[?:ShootDay, day == wanted]];
}

impl CallSheet.on_day {
    visit [here ->:Scheduled:->];
}

impl CallSheet.on_scene {
    if here.location not in self.places {
        self.places.append(here.location);
    }
    for c in [here <-:AssignedTo:<-] {
        for a in [edge c ->:AssignedTo:-> here] {
            t = here.start_min - prep_minutes(c.dept) - a.early;
            if c.name not in self.best or t < self.best[c.name] {
                self.best[c.name] = t;
                self.crew[c.name] = c;
            }
        }
    }
}

impl CrewDays.start {
    visit [here ->:AssignedTo:->];
}

impl CrewDays.on_scene {
    for d in [here <-:Scheduled:<-] {
        if d.day not in self.days {
            self.days.append(d.day);
        }
    }
}

impl prep_minutes(dept: Department) -> int {
    match dept {
        case Department.MAKEUP:
            return 120;
        case Department.WARDROBE:
            return 90;
        case Department.CAMERA:
            return 60;
        case _:
            return 30;
    }
}

impl clock(minutes: int) -> str {
    return f"{minutes // 60:02d}:{minutes % 60:02d}";
}

impl find_crew(name: str) -> Crew | None {
    wanted = name;
    found = [root -->[?:Crew, name == wanted]];
    return found[0] if found else None;
}

impl find_scene(number: str) -> Scene | None {
    wanted = number;
    for d in [root -->[?:ShootDay]] {
        found = [s for s in [d ->:Scheduled:->] if s.number == wanted];
        if found {
            return found[0];
        }
    }
    return None;
}

impl shoot_day(day: int) -> ShootDay {
    wanted = day;
    found = [root -->[?:ShootDay, day == wanted]];
    return found[0] if found else root ++> ShootDay(day=day);
}

impl hire(name: str, dept: str) -> bool {
    if find_crew(name) is not None or dept not in [d.value for d in Department] {
        return False;
    }
    root ++> Crew(name=name, dept=Department(dept));
    return True;
}

impl add_scene(day: int, number: str, start: str, location: str) -> bool {
    if find_scene(number) is not None {
        return False;
    }
    parts = start.split(":");
    shoot_day(day) +>:Scheduled():+> Scene(
        number=number, start_min=int(parts[0]) * 60 + int(parts[1]), location=location
    );
    return True;
}

impl assign(name: str, scene: str, early: int = 0) -> bool {
    c = find_crew(name);
    sc = find_scene(scene);
    if c is None or sc is None or sc in [c ->:AssignedTo:->] {
        return False;
    }
    c +>:AssignedTo(early=early):+> sc;
    return True;
}

impl call_sheet(day: int) -> list[str] {
    w = root spawn CallSheet(day=day);
    order = [row.split(" ", 1)[1] for row in sorted([f"{t:05d} {n}" for (n, t) in w.best.items()])];
    return [f"{clock(w.best[n])} {n} ({w.crew[n].dept.name})" for n in order];
}

impl locations(day: int) -> list[str] {
    return sorted((root spawn CallSheet(day=day)).places);
}

impl crew_days(name: str) -> list[int] {
    c = find_crew(name);
    if c is None {
        return [];
    }
    return sorted((c spawn CrewDays()).days);
}

impl idle(dept: str) -> list[str] {
    return sorted([c.name for c in [root -->[?:Crew]] if c.dept.value == dept and not [c ->:AssignedTo:->]]);
}
