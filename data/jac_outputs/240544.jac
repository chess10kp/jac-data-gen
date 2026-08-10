"""
Use the information that 0 and 1 color will be close for us and info about the frequencies of similar objects
to change the colors to new ones
"""
def recolor_by_frequency(colors: dict[int, int]) -> dict[int, int] {
    values = list(colors.values());
    replace_dict = {
        val: ind
        for (ind, val) in enumerate(
            sorted(
                set(colors.values()),
                key=lambda (x: int) { values.count(colors[x]); }
            )
        )
    };
    result_dict = {};
    for key in colors {
        result_dict[key] = replace_dict[colors[key]];
    }
    return result_dict;
}