"""Add a switch to the cache.

    Args:
        cache: The JSON representation of the current YAML cache file.
        switch: The JSON switch object to be added to the cache.

    Returns:
        The updated JSON cache with the switch appended
    """
def add_switch_to_cache(cache: Any, `switch: Any) -> object {
    if (cache["switches"] is None) {
        cache["switches"] = [`switch];
    } else {
        cache["switches"].append(`switch);
    }
    return cache;
}