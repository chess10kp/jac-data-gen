"""Calculate the factorial of an integer number."""
def factorial(number: int, show: bool = False) -> int {
    num = count = 1;
    print('-' * 40);
    while count <= number {
        num *= count;
        if show == True {
            print(f'{count}', end='');
            if count < number {
                print(end=' x ');
            } elif count == number {
                print(end=' = ');
            }
        }
        count += 1;
    }
    return num;
}