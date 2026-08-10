"""Deeply merge dictionary2 and dictionary1 then return a new dictionary"""
def deep_merge(dict1: dict, dict2: dict) -> dict {
    if (`type(dict1) is dict) and (`type(dict2) is dict) {
        dict1_copy = dict1.copy();
        for key in dict2.keys() {
            if key in dict1 and `type(dict1[key]) is dict and `type(dict2[key]) is dict {
                dict1_copy[key] = deep_merge(dict1[key], dict2[key]);
            } else {
                dict1_copy[key] = dict2[key];
            }
        }
        return dict1_copy;
    }
    return dict1;
}