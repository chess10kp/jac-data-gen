def factorial(n: int):
    """
    >>> factorial(5)
    120
    >>> factorial(4)
    24
    """
    resultado = 1
    for i in range(1, n + 1):
        resultado = resultado * i
    return resultado

assert factorial(10) == 3628800
assert factorial(5) == 120
assert factorial(8) == 40320
assert factorial(1) == 1
assert factorial(4) == 24
assert factorial(0) == 1
assert factorial(2) == 2
assert factorial(7) == 5040
assert factorial(6) == 720
assert factorial(3) == 6
assert factorial(9) == 362880
