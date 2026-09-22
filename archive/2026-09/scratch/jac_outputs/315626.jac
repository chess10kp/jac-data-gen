"""Collect metadata for adding it to a layer."""
def _collect_layer_metadata(config: dict[str, dict[str, str]], layer_config: dict[str, str]) -> dict[str, str] {
    meta = config.get("common_items", dict()).copy();
    meta.update(layer_config);
    if "title" not in meta and "title_pattern" in meta {
        meta["title"] = meta["title_pattern"];
    }
    return meta;
}