"""
Two step:
0. under the same backends pair
* 1. the same input, choose largest.
2. different inputs with small distance. Do not update
"""
def add_into_dict(input_key: str, incon_tuple: tuple, incon_dict: dict) -> dict {
    if input_key not in incon_dict or incon_dict[input_key][1] < incon_tuple[1] {
        incon_dict[input_key] = incon_tuple;
    }
    return incon_dict;
}