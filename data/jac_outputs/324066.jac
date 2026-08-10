"""prints fibonacci sequence
       pass a number to the function fib(x)
    """
def fib(n: int) -> int {
    (a, b) = (0, 1);
    counter = 1;
    while counter < n {
        print(a, end=' ');
        (a, b) = (b, a + b);
        counter += 1;
    }
    print(a);
    print(__name__);
    return 0;
}