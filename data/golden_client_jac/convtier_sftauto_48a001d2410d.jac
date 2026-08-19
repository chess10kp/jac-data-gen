def fibonacci(n: Any) -> object {
    if (n <= 0) {
        return [];
    } elif (n == 1) {
        return [0];
    } elif (n == 2) {
        return [0, 1];
    } else {
        fib_list = fibonacci((n - 1));
        fib_list.append((fib_list[-1] + fib_list[-2]));
        return fib_list;
    }
}



with entry {
    print(fibonacci(2));
    print(fibonacci(0));
    print(fibonacci(1));
}
