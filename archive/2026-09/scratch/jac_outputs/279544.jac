def create_unique_id_for_nodes(input_objs: dict[str, list[dict[str, int]]], start_no: int) -> dict[str, list[dict[str, int]]] {
    current_no = start_no;
    if 'nodes' in input_objs {
        for `node in input_objs['nodes'] {
            `node['id'] = current_no;
            current_no = current_no + 1;
        }
    }
    return input_objs;
}