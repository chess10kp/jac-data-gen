"""
    Return an array containing the numbers from 1 to N, where N is the parametered value. N will never be less than 1.
    :param n: an integer value.
    :return: an array with integers and FizzBuzz.
    """
def fizzbuzz(n: Any) -> object {
    final = [];
    for i in range(1, (n + 1)) {
        if (((i % 3) == 0) and ((i % 5) == 0)) {
            final.append("FizzBuzz");
        } elif ((i % 3) == 0) {
            final.append("Fizz");
        } elif ((i % 5) == 0) {
            final.append("Buzz");
        } else {
            final.append(i);
        }
    }
    return final;
}