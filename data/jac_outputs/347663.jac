"""Enrich start list with next race info."""
def get_next_race_info(next_race_time_events: list[dict[str, str]], race_id: str) -> list[dict[str, str | int]] {
    startlist = [];
    for x in range(1, 9) {
        for template in next_race_time_events {
            start_entry = {};
            _rank = template["rank"];
            if template["timing_point"] == "Template" and _rank.isnumeric() {
                if int(_rank) == x {
                    start_entry["race_id"] = race_id;
                    start_entry["starting_position"] = x;
                    if template["next_race"].startswith("Ute") {
                        start_entry["next_race"] = "Ute";
                    } else {
                        start_entry["next_race"] = f"{template['next_race']}-{template['next_race_position']}";
                    }
                    startlist.append(start_entry);
                }
            }
        }
    }
    return startlist;
}