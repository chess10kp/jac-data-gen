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

"""Minutes before their first scene that each department must be on set."""
def prep_minutes(dept: Department) -> int {
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
