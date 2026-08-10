"""An algorithm that no matter what positive number you give, it will return 1."""
def collatz(number: Any) -> object {
    number = int(number);
    if ((number % 2) == 0) {
        print((number // 2));
        return (number // 2);
    } elif ((number % 2) == 1) {
        result = (3 * number) + 1;
        print(result);
        return result;
    }
}