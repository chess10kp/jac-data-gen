"""
Deal with components that have multiple values and multiple IDs from
id-value dicts
(can be found inside def process_inputs; dicts pre-processed inside the
function)
"""
def multi_inputs(dicts: dict[str, str]) -> dict[str, str | list[str]] {
    dict_list = {};
    for (k, v) in dicts.items() {
        if k[-1:].isnumeric() is False {
            dict_list.update({k: v});
        } elif k[:-2] not in dict_list {
            dict_list.update({k[:-2]: v});
        } elif k[:-2] in dict_list {
            if not isinstance(dict_list[k[:-2]], list) {
                new_list = [dict_list[k[:-2]]];
            } else {
                new_list = dict_list[k[:-2]];
            }
            new_list.append(v);
            dict_list.update({k[:-2]: new_list});
        }
    }
    return dict_list;
}