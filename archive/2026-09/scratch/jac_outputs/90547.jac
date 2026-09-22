"""
    input : sequence_list -> [[s1],[s2],[s3],[s4] ....,[sn]] where sn is prediction vector
    output: tokenized sequence_list -> [1,2,3,2,3,....,678] and a look_up table -> {[s1]:0,[s2]:1,[s3]:2,[s4]:3 ....,[sn]:n-1}
    """
def tokenization(sequence_list: list[list[float]]) -> tuple[list[int], dict[int, list[float]]] {
    lookup_table: dict[int, list[float]] = {};
    tokenized_sequence_list: list[int] = [];
    index = 0;
    for predicton_vector in sequence_list {
        if predicton_vector not in lookup_table.values() {
            lookup_table[index] = predicton_vector;
            tokenized_sequence_list.append(index);
            index += 1;
        } else {
            tokenized_sequence_list.append(
                list(lookup_table.keys())[
                    list(lookup_table.values()).index(predicton_vector)
                ]
            );
        }
    }
    return (tokenized_sequence_list, lookup_table);
}