"""Production crew."""

enum Department {
    CAMERA,
    SOUND,
    MAKEUP,
    WARDROBE,
    GRIP
}

node Crew {
    has name: str;
    has dept: Department;
}

glob PREP: dict[str, int] = {"MAKEUP": 120, "WARDROBE": 90, "CAMERA": 60};

def prep_minutes(dept: Department) -> int {
    return PREP.get(dept.name, 30);
}
