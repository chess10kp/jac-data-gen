"""Checks that a list of values matches the form specified in a format list."""
def parse_list_result(match_list: list[str | tuple[str, type]], raw_list: list[str]) -> dict[str, int | float] {
    if len(match_list) != len(raw_list) {
        raise Exception(
            'len("{}") != len("{}") ({}, {})'.format(
                match_list, raw_list, len(match_list), len(raw_list)
            )
        );
    }
    res: dict[str, int | float] = {};
    for (idx, `match) in enumerate(match_list) {
        data = raw_list[idx];
        if isinstance(`match, tuple) {
            (key, conv_fn) = `match;
            res[key] = conv_fn(data);
        } elif `match != data {
            raise Exception('"{}" != "{}" ({})'.format(`match, data, idx));
        }
    }
    return res;
}