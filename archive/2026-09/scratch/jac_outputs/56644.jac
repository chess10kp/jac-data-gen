"""Flatten a dictionary."""
def flatten_dict(
    input_: dict | list | str | int | float | bool | None,
    prefix: list[str] | None = None,
    join_with: str = ".",
    filter_none: bool = True
) -> dict[str, str | int | float | bool | None] {
    if prefix is None {
        prefix = [];
    }
    if isinstance(input_, list) {
        result = {};
        for v in input_ {
            result.update(flatten_dict(v, prefix, join_with, filter_none));
        }
        return result;
    }
    if isinstance(input_, dict) {
        result = {};
        for (k, v) in input_.items() {
            prefix.append(k);
            result.update(flatten_dict(v, prefix, join_with, filter_none));
            prefix.pop();
        }
        return result;
    }
    if filter_none and input_ is None {
        return {};
    }
    return {join_with.join(prefix): input_};
}