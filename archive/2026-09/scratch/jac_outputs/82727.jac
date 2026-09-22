def one_hot_encode(
    input_field: str,
    output_field: str,
    options: list[str | int | float],
    function_name: str,
    field_prefix: str = ""
) -> list[str] {
    lines = [];
    for option in options {
        key = option;
        if `type(option) == str {
            key = f'"{option}"';
        }
        lines.append(
            f'event["{output_field}_{field_prefix}{option}"] = {function_name}(event["{input_field}"])[{key}]'
        );
    }
    return lines;
}