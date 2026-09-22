glob MOD = 1000000007;

"""Number of swaps."""
def inversions(constants: int, variables: int) -> int {
    if variables {
        pow2 = pow(2, variables - 1, MOD);
        return pow2 * (constants * 2 + variables);
    }
    return constants;
}