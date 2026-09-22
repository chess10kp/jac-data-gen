"""
Returns n-th Fibonacci number
n must be more than 0, otherwise it raises a ValueError.
>>> recursive_fibonacci_cache(0)
0
>>> recursive_fibonacci_cache(1)
1
>>> recursive_fibonacci_cache(2)
1
>>> recursive_fibonacci_cache(10)
55
>>> recursive_fibonacci_cache(-2)
Traceback (most recent call last):
    ...
ValueError: n must be more or equal than 0
"""
def recursive_fibonacci_cache(n: int) -> int {
    cache: dict[int, int] = {};
    def _fib(_n: int) -> int {
        if _n < 0 {
            raise ValueError('n must be more or equal than 0');
        }
        if _n == 0 {
            return 0;
        } elif _n == 1 {
            return 1;
        }
        if _n not in cache {
            if (_n - 1) not in cache {
                cache[_n - 1] = _fib(_n - 1);
            }
            if (_n - 2) not in cache {
                cache[_n - 2] = _fib(_n - 2);
            }
            cache[_n] = cache[_n - 1] + cache[_n - 2];
        }
        return cache[_n];
    }
    return _fib(n);
}