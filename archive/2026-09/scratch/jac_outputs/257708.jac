"""
    This is a mathematical problem. odd numbers are only divisible by odd numbers.
    If player starts with even number he can always choose 1 as it's next number
    remaining player 2 with odd number.
    In extreme scenario each player can reduce 1 at its turn resulting
    that if the start player has odd number he losses and wins for even number
    """
def divisor_game(N: int) -> bool {
    N % 2 == 0
}