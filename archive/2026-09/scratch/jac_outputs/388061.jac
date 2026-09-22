"""Fold dict `data`.

Turns dictionary keys, e.g. 'level1/level2/level3', into sub-dicts.
"""
def fold_dict(data: dict[str, object], nb_level: int = (10 ** 5)) -> dict[str, object] {
    if nb_level <= 0 {
        return data;
    }
    groups: dict[str, object] = dict();
    levels = set();
    for (key, value) in data.items() {
        idx = key.find('/');
        if idx > 0 {
            level = key[:idx];
            group_dict = groups.setdefault(level, dict()) as dict[str, object];
            group_dict[key[(idx + 1):]] = value;
            levels.add(level);
        } else {
            groups[key] = value;
        }
    }
    for level in levels {
        groups[level] = fold_dict(groups[level] as dict[str, object], nb_level - 1);
    }
    return groups;
}