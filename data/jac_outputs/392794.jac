"""
Returns a list of tuples that preserves the qbbo_types and Id keys.

(The input is what you get when you run quickbooks.transactions()
 or quickbooks.names())

Each item in list is a three-item tuple:
(qbbo_type,Id,raw_entity_dict)
"""
def entity_list(raw_entities_dict: dict[str, dict[str, dict[str, str | int | float]]]) -> list[tuple[str, str, dict[str, str | int | float]]] {
    e_list = [];
    for qbbo in raw_entities_dict {
        for entity_id in raw_entities_dict[qbbo] {
            raw_qbbo_dict = raw_entities_dict[qbbo][entity_id];
            e_list.append((qbbo, entity_id, raw_qbbo_dict));
        }
    }
    return e_list;
}