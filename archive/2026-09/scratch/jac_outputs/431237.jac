"""Get the floating latest, from a random list of API versions."""
def get_floating_latest(api_versions_list: list[str], preview_mode: bool) -> str {
    api_versions_list = list(api_versions_list);
    absolute_latest = sorted(api_versions_list)[-1];
    trimmed_preview = [
        version
        for version in api_versions_list
        if "preview" not in version
    ];
    if not trimmed_preview {
        return absolute_latest;
    }
    if preview_mode {
        return absolute_latest;
    }
    return sorted(trimmed_preview)[-1];
}