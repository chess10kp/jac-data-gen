"""
Toy fitness function, returns 2^x, where x is the number of 'one' bits in
the bit string.
"""
def fitness(bit_string: list[int]) -> int {
    2 ** sum(bit_string)
}