"""
Take the input ids for sequences 0 and 1 (claim and evidence) and a tokenizer function.
Apply function to tuples of claim-evidence.
Return list of token type ids.
"""
def transform_input_ids(
    input_ids_0: list[list[int]],
    input_ids_1: list[list[int]],
    tokenizer_func: Callable[[list[int], list[int]], list[int]]
) -> list[list[int]] {
    [
        tokenizer_func(ids_tuple[0], ids_tuple[1])
        for ids_tuple in zip(input_ids_0, input_ids_1)
    ]
}