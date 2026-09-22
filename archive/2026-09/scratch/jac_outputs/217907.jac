"""Removes empty keys from dictionary."""
def remove_empty_from_dict(
    d: dict[str, object] | list[object] | str | int | float | bool | None
) -> dict[str, object] | list[object] | str | int | float | bool | None {
    if isinstance(d, dict) {
        return dict(
            (k, remove_empty_from_dict(v as dict[str, object] | list[object] | str | int | float | bool | None))
            for (k, v) in d.items()
            if v and remove_empty_from_dict(v as dict[str, object] | list[object] | str | int | float | bool | None)
        );
    } elif isinstance(d, list) {
        return [
            remove_empty_from_dict(v as dict[str, object] | list[object] | str | int | float | bool | None)
            for v in d
            if v and remove_empty_from_dict(v as dict[str, object] | list[object] | str | int | float | bool | None)
        ];
    } else {
        return d;
    }
}