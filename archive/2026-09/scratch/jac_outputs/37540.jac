"""Return all citation keys."""
def bib_keys(config: dict[str, object]) -> set[str] {
    if "bib_data" not in config {
        return set();
    }
    bib_data = config["bib_data"] as list[dict[str, str]];
    return {entry["ID"] for entry in bib_data};
}