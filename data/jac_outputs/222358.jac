"""This function takes a target dictionary and returns the float value given by the given key.
    Returns None if key if not found and appends any error messages to the post_errors list"""
def clean_float_value_from_dict_object(
    dict_object: dict[str, float | int | str | None],
    dict_name: str,
    dict_key: str,
    post_errors: list[str],
    none_allowed: bool = False,
    no_key_allowed: bool = False
) -> float | None {
    if dict_key not in dict_object {
        if no_key_allowed {
            return None;
        }
        post_errors.append(
            "{!r} key not found in {!r} object".format(dict_key, dict_name)
        );
    } elif dict_object[dict_key] is None and not none_allowed {
        post_errors.append(
            "Value for {!r} in {!r} object is Null".format(dict_key, dict_name)
        );
    } elif (
        dict_object[dict_key] is None and not none_allowed
        and not isinstance(dict_object[dict_key], float)
        and not isinstance(dict_object[dict_key], int)
    ) {
        post_errors.append(
            "Value for {!r} in {!r} object is not an float".format(dict_key, dict_name)
        );
    } elif dict_object[dict_key] == '' {
        post_errors.append(
            "Value for {!r} in {!r} object is and empty string".format(
                dict_key, dict_name
            )
        );
    } else {
        return float(dict_object[dict_key] as float | int | str);
    }
}