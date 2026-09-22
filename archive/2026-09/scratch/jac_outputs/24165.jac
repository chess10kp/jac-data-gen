"""Builds a dictionary mapping edition keys to their root name.

    The dictionary takes the form of:
        {
         "A.":   "A.",
         "A.2d": "A.",
         "A.3d": "A.",
         "A.D.": "A.D.",
         ...
        }

    In other words, this lets you go from an edition match to its parent key.
    """
def suck_out_editions(reporters: dict[str, list[dict[str, dict[str, object]]]]) -> dict[str, str] {
    editions_out = {};
    for (reporter_key, data_list) in reporters.items() {
        for data in data_list {
            for (edition_key, edition_value) in data["editions"].items() {
                if edition_key not in editions_out {
                    editions_out[edition_key] = reporter_key;
                }
            }
        }
    }
    return editions_out;
}