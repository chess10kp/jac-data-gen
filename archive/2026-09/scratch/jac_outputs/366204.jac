"""
    Merges ``src`` onto ``dst`` in a deep-copied data structure, overriding data
    in ``dst`` with ``src``.

    Both ``dst`` and ``src`` are left intact; and also, they will not share
    objects with the resulting data structure either. This avoids side-effects
    when the result structure is modified, which would cause the original
    ``dst`` to receive modifications if deep copy had not been used.
    """
def dict_merge(dst: dict[str, int | float | str | bool | list | dict], src: dict[str, int | float | str | bool | list | dict]) -> dict[str, int | float | str | bool | list | dict] {
    import copy;
    def rec_merge(dst: dict[str, int | float | str | bool | list | dict], src: dict[str, int | float | str | bool | list | dict]) -> dict[str, int | float | str | bool | list | dict] {
        dst = copy.copy(dst);
        for (key, val) in list(src.items()) {
            if key in dst and isinstance(val, dict) and isinstance(dst[key], dict) {
                dst[key] = rec_merge(dst[key], val);
            } else {
                dst[key] = copy.copy(val);
            }
        }
        return dst;
    }
    return rec_merge(dst, src);
}