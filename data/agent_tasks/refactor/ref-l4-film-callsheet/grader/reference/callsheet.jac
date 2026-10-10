"""Film production call sheets: crew report a department-specific time before their first scene of the day.

Graph: root -> ShootDay -Scheduled-> Scene <-AssignedTo(early)- Crew <- root.
Bodies live in callsheet.impl.jac.
"""

enum Department {
    CAMERA = "camera",
    SOUND = "sound",
    MAKEUP = "makeup",
    WARDROBE = "wardrobe",
    GRIP = "grip"
}

node Crew {
    has name: str;
    has dept: Department;
}

node ShootDay {
    has day: int;
}

node Scene {
    has number: str;
    has start_min: int;
    has location: str;
}

edge Scheduled: ShootDay --> Scene {}

"""early = extra minutes on top of the department's prep."""
edge AssignedTo: Crew --> Scene {
    has early: int = 0;
}

"""Spawned on root: earliest call per crew member for one shooting day, plus its locations."""
walker CallSheet {
    has day: int;
    has best: dict[str, int] = {};
    has crew: dict[str, Crew] = {};
    has places: list[str] = [];

    can start with Root entry;
    can on_day with ShootDay entry;
    can on_scene with Scene entry;
}

"""Spawned on a Crew node: the days they have scenes on."""
walker CrewDays {
    has days: list[int] = [];

    can start with Crew entry;
    can on_scene with Scene entry;
}

def prep_minutes(dept: Department) -> int;
def clock(minutes: int) -> str;
def find_crew(name: str) -> Crew | None;
def find_scene(number: str) -> Scene | None;
def shoot_day(day: int) -> ShootDay;
def hire(name: str, dept: str) -> bool;
def add_scene(day: int, number: str, start: str, location: str) -> bool;
def assign(name: str, scene: str, early: int = 0) -> bool;
def call_sheet(day: int) -> list[str];
def locations(day: int) -> list[str];
def crew_days(name: str) -> list[int];
def idle(dept: str) -> list[str];
