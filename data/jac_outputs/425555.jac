"""Return aggregate entities in descending order by count."""
def agg_across_entities(entity_lists_by_doc: dict[str, dict[str, int]]) -> list[str] {
    if not entity_lists_by_doc or len(entity_lists_by_doc) == 0 {
        return [];
    }
    result_set: dict[str, int] = {};
    for doc_id in entity_lists_by_doc.keys() {
        cur_list = entity_lists_by_doc[doc_id];
        for (name, count) in cur_list.items() {
            result_set[name] = result_set.get(name, 0) + count;
        }
    }
    return [
        it[0]
        for it in sorted(
            result_set.items(), key=lambda (x) { x[1]; }, reverse=True
        )
    ];
}