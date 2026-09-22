"""Return the Hamming weight of n."""
def hammingWeight(n: int) -> int {
    num_ones = 0;
    binary_string = bin(n);
    for elem in binary_string {
        if elem == '1' {
            print(elem);
            num_ones += 1;
        }
    }
    if n == 0 {
        return 0;
    } elif n < 0 {
        return 32 - num_ones;
    } else {
        return num_ones;
    }
}