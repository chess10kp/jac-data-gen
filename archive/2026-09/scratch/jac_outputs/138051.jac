"""Get level name."""
def get_level_name(adeptus: str, level: int) -> list[int | str] {
    level_dictionary = {
        "Adeptus Astra Telepathica": "Magister Telepathicae",
        "Adeptus Astra Militarum": "Legionary Astartes",
        "Adeptus Mechanicus": "Techno-Priest",
        "Adeptus Officio Assassinorum": "Night Haunter",
        1: "Acolyte",
        2: "Inquisitor"
    };
    if level != 3 {
        return [level, level_dictionary[level]];
    }
    return [level, level_dictionary[adeptus]];
}