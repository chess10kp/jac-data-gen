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
