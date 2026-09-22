"""
    Designed to split up output from -o=name into a
    simple list of qualified object names ['kind/name', 'kind/name', ...]
    :param output: A single string containing all of the output to parse
    :return: A list of qualified object names
    """
def split_names(output: str | None) -> list[str] {
    if output is None {
        return [];
    }
    return [
        x.strip()
        for x in output.strip().split("\n")
        if x.strip() != ""
    ];
}