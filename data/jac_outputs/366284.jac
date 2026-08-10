"""Parses a hyphenated range into a list of integers."""
def _parse_hyphenated_string(s: str) -> list[int] {
    list_of_lists = [
        list(
            range(
                *[
                    int(second) + int(first)
                    for (second, first) in enumerate(substring.split('-'))
                ]
            )
        )
            if '-' in substring
            else [int(substring)] for substring in s.split()
    ];
    return [item for sublist in list_of_lists for item in sublist];
}