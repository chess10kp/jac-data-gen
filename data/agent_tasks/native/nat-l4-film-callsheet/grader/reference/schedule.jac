"""Shooting schedule: ShootDay -Scheduled-> Scene, Crew -AssignedTo-> Scene."""
import from crew { Crew, Department }

node ShootDay {
    has day: int;
}

node Scene {
    has number: str;
    has start_min: int;    # minutes after midnight
    has location: str;
}

edge Scheduled: ShootDay --> Scene {}

edge AssignedTo: Crew --> Scene {}

def shoot_day(day: int) -> ShootDay {
    found = [d for d in [root -->[?:ShootDay]] if d.day == day];
    return found[0] if found else root ++> ShootDay(day=day);
}

def add_scene(day: int, number: str, start_min: int, location: str) -> Scene {
    sc = Scene(number=number, start_min=start_min, location=location);
    shoot_day(day) +>:Scheduled():+> sc;
    return sc;
}

def hire(name: str, dept: Department) -> Crew {
    return root ++> Crew(name=name, dept=dept);
}

def assign(c: Crew, sc: Scene) {
    c +>:AssignedTo():+> sc;
}
