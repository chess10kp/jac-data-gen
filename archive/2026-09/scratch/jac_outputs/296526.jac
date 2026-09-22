"""
Iterative DFS to merge 2 dicts with nested dict
a = {'a', {'j': 2, 'b': 1}, c: 1, e: 4}
b = {'a': {'k': 4, 'b': 12}, d: 2, e: 5}

{'a':{'j': 2, 'k': 4, 'b': 12}, c: 1, d: 2, e: 5}
"""
def deep_dict_merge(from_file: dict, from_env: dict) -> dict {
    conf_data = {};
    stack = [(conf_data, from_file, from_env)];
    while stack {
        (conf, dict1, dict2) = stack.pop();
        for key in dict1 {
            if isinstance(dict1[key], dict) and isinstance(dict2.get(key), dict) {
                conf[key] = {};
                stack.append((conf[key], dict1[key], dict2[key]));
                continue;
            }
            conf[key] = dict2.get(key, dict1[key]);
        }
        for (key, val) in dict2.items() {
            conf.setdefault(key, val);
        }
    }
    return conf_data;
}