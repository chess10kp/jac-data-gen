"""This will parse out the version string from the given list of lines. If no
version string can be found a ValueError will be raised."""
def get_version(raw: list[str]) -> str {
    for line in raw {
        if line.startswith("# MODULE:") {
            (_, version) = line.split(":", 1);
            return version.strip();
        }
    }
    raise ValueError("Could not determine the version");
}