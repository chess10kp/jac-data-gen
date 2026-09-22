"""
This Function will return all prime numbers by range of limiter.
the limiter must be between 2 - 100.
"""
def GetPrimeNumbers(limiter: int = 2) -> list[int] {
    prime_num_list = [];
    if limiter >= 2 and limiter <= 100 {
        for x in range(limiter) {
            prime_num_list.append(x);
        }
    }
    return prime_num_list;
}