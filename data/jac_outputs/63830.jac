"""
   Return the bit length of input.
   EX: 7 (0b111) has length 3
   EX: 8 (0b1000) has length 4
   """
def bit_length(input: Any) -> object {
    return (len(bin(input)) - 2);
}