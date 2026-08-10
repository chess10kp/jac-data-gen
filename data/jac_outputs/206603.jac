"""
Helper function for storing unique names which may have special characters
stripped and restricted to a maximum length.
"""
def unique_name(
    key: int | str,
    name: str,
    name_dict: dict[int | str, str],
    name_max: int = -1,
    clean_func: Callable[[str], str] | None = None,
    sep: str = "."
) -> str {
    cached = name_dict.get(key);
    if cached is not None {
        return cached;
    }
    count = 1;
    name_dict_values = name_dict.values();
    name_new = name_new_orig = name if clean_func is None else clean_func(name);
    if name_max == -1 {
        while name_new in name_dict_values {
            name_new = "%s%s%03d" % (name_new_orig, sep, count);
            count += 1;
        }
    } else {
        name_new = name_new[:name_max];
        while name_new in name_dict_values {
            count_str = "%03d" % count;
            name_new = (
                "%.*s%s%s"
                % ((name_max - (len(count_str) + 1)), name_new_orig, sep, count_str)
            );
            count += 1;
        }
    }
    name_dict[key] = name_new;
    return name_new;
}