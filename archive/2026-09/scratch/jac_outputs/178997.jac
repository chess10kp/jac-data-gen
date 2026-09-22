"""Build a resource based on a list of properties given as key-value pairs. Leave properties with empty values out of the inserted resource."""
def get_api_request_dict(properties: dict[str, object]) -> dict[str, object] {
    resource = {};
    for p in properties {
        prop_array = p.split('.');
        ref = resource;
        for (pa, _) in enumerate(prop_array) {
            is_array = False;
            key = prop_array[pa];
            if key[-2:] == '[]' {
                key = key[0:len(key) - 2];
                is_array = True;
            }
            if pa == len(prop_array) - 1 {
                if properties[p] {
                    if is_array {
                        if isinstance(properties[p], str) {
                            ref[key] = properties[p].split(',');
                        } else {
                            ref[key] = properties[p];
                        }
                    } else {
                        ref[key] = properties[p];
                    }
                }
            } elif key not in ref {
                ref[key] = {};
                ref = ref[key];
            } else {
                ref = ref[key];
            }
        }
    }
    return resource;
}