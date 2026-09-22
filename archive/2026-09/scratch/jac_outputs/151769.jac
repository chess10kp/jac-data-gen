"""Find the latest versions of the experiments."""
def _find_latest_versions(experiments: list[dict[str, str | int]]) -> dict[str, str | int] {
    leaf_experiments: dict[str, str | int] = {};
    for experiment in experiments {
        name = experiment["name"] as str;
        version = experiment["version"] as str | int;
        if name in leaf_experiments {
            leaf_experiments[name] = max(leaf_experiments[name], version);
        } else {
            leaf_experiments[name] = version;
        }
    }
    return leaf_experiments;
}