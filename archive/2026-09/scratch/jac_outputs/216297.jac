"""Extend slice."""
def extend_slice(
    slice_name: str,
    slices: list[dict[str, str | list[int]]],
    template_size: int,
    target_result: list[dict[str, str | float]]
) -> list[dict[str, str | float]] {
    ext_obj = {"name": "Empty", "score": 0.0};
    extended_list = [ext_obj] * template_size;
    el = extended_list;
    for slice in slices {
        if slice["name"] == slice_name {
            print("Slice:", slice_name);
            template_slice = slice["template_slice"] as list[int];
            for (i, n) in enumerate(template_slice) {
                pos = n - 1;
                el = el[:pos] + [target_result[i]] + el[(pos + 1):];
            }
        }
    }
    return el;
}