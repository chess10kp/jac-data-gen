"""Convert coupling map list into dictionary.

    Example list format: [[0, 1], [0, 2], [1, 2]]
    Example dictionary format: {0: [1, 2], 1: [2]}

    We do not do any checking of the input.

    Return coupling map in dict format.
    """
def coupling_list2dict(couplinglist: list[list[int]]) -> dict[int, list[int]] | None {
    if not couplinglist {
        return None;
    }
    couplingdict: dict[int, list[int]] = {};
    for pair in couplinglist {
        if pair[0] in couplingdict {
            couplingdict[pair[0]].append(pair[1]);
        } else {
            couplingdict[pair[0]] = [pair[1]];
        }
    }
    return couplingdict;
}