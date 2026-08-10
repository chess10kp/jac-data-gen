"""Check if a number is in the Fibonacci sequence."""
def isfib(number: int) -> bool {
    num1 = 1;
    num2 = 1;
    while True {
        if num2 < number {
            tempnum = num2;
            num2 += num1;
            num1 = tempnum;
        } elif num2 == number {
            return True;
        } else {
            return False;
        }
    }
}