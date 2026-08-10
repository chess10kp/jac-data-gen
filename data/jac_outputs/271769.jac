"""Filter out nested layers from containers."""
def filter_empty_layer_containers(layer_list: list[object]) -> list[object] {
    existing = set();
    to_visit = layer_list[::-1];
    filtered = [];
    while to_visit {
        `obj = to_visit.pop();
        obj_id = id(`obj);
        if obj_id in existing {
            continue;
        }
        existing.add(obj_id);
        if hasattr(`obj, '_layers') {
            filtered.append(`obj);
            to_visit.extend(getattr(`obj, 'layers')[::-1]);
        }
    }
    return filtered;
}