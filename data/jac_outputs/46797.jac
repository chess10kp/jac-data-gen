"""Parses each element in data using a formatter function.
Data is a dict, each key is a category and each value is a list of dicts.
Adds a header for each category."""
def parse_categorised_lists(
    data: dict[str, list[dict[str, str]]],
    header_formatter: Callable[[str], str],
    formatter: Callable[[dict[str, str]], str],
    list_parser: Callable[[list[dict[str, str]], Callable[[dict[str, str]], str]], str],
    sorted_keys: list[str] | None = None
) -> str {
    if sorted_keys is None {
        sorted_keys = sorted(data.keys(), reverse=True);
    }
    return "".join(
        header_formatter(key) + list_parser(data[key], formatter)
        for key in sorted_keys
    );
}