"""I need to ensure that NetSurfP is not overwhelmed - so I split the queries to ensure that each is less than Max
	I will use Max = 100000"""
def dont_exceed_max(Max: int, code_list: list[tuple[str, str]]) -> list[list[tuple[str, str]]] {
    temp_list = [];
    for_inclusion = [];
    limit = 0;
    for (a, b) in code_list {
        B = len(b);
        if limit + B < Max {
            for_inclusion.append((a, b));
            limit += B;
        } else {
            temp_list.append(for_inclusion);
            limit = B;
            for_inclusion = [(a, b)];
        }
    }
    temp_list.append(for_inclusion);
    return temp_list;
}