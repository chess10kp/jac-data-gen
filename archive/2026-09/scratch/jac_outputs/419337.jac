"""
    This function is for parsing a nested string structure into a nested list

    >>>parse("hello world")
    ["hello", "world"]

    >>>parse("a b (c d (e f)) g")
    ["a", "b", ["c", "d", ["e", "f"]], "g"]
    """
def parse(
    string: str, delimiter: str = ' ', nest_open: str = '(', nest_close: str = ')'
) -> list {
    nest = [];
    openers = [];
    closers = [];
    nest_pairs = [];
    for (index, character) in enumerate(string) {
        if (character == nest_open) {
            openers.append(index);
        } elif (character == nest_close) {
            closers.append(index);
        }
        if (openers and closers and (len(openers) >= len(closers))) {
            if (openers[-1] > closers[0]) {
                raise ValueError(f"Cannot parse {string}, invalid parentheses");
            }
            nest_pairs.append((openers.pop(-1), closers.pop()));
        }
    }
    if nest_pairs {
        for (pair_index, (open_index, close_index)) in enumerate(nest_pairs) {
            nested = False;
            for (sub_pair_index, (sub_open_index, sub_close_index)) in enumerate(
                nest_pairs
            ) {
                if (pair_index == sub_pair_index) {
                    continue;
                }
                if (
                    (open_index > sub_open_index) and (close_index < sub_close_index)
                ) {
                    nested = True;
                }
            }
            if not nested {
                parsed_sub = parse(
                    string=string[(open_index + 1):close_index],
                    delimiter=delimiter,
                    nest_open=nest_open,
                    nest_close=nest_close
                );
                nest.append(parsed_sub);
            }
        }
        string = ''.join(
            [
                char
                for (index, char) in enumerate(string)
                if not [
                    index
                    for (start, end) in nest_pairs
                    if ((index >= start) and (index <= end))
                ]
            ]
        );
    }
    nest.extend(
        [
            word
            for word in string.split(delimiter)
            if word
        ]
    );
    return nest;
}