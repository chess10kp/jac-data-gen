"""Rearrange result_map to use typ tags as the top-level keys."""
def _ReorderMapByTypTags(result_map: dict[str, dict[str, dict[tuple[str, ...], list[str]]]]) -> dict[tuple[str, ...], dict[str, dict[str, list[str]]]] {
    reordered_map = {};
    for (suite, test_map) in result_map.items() {
        for (test, tag_map) in test_map.items() {
            for (typ_tags, build_url_list) in tag_map.items() {
                reordered_map.setdefault(typ_tags, {}).setdefault(suite, {})[test] = build_url_list;
            }
        }
    }
    return reordered_map;
}