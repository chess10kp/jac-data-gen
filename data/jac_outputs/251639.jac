"""
    Return the length of the longest benchmark name in a given list of
    benchmark JSON objects
    """
def find_longest_name(benchmark_list: list[dict[str, str]]) -> int {
    longest_name = 1;
    for bc in benchmark_list {
        if len(bc['name']) > longest_name {
            longest_name = len(bc['name']);
        }
    }
    return longest_name;
}