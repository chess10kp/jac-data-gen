# Simple lambda (note spacing around type annotations)
glob add = lambda a: int , b: int -> int : a + b;

# Multi-statement logic reads better as a named function than a block lambda
def process(x: int) -> int {
    result = x * 2;
    result += 1;
    return result;
}

# Lambda without parameters
glob get_value = lambda : 42;

# Lambda with return type only
glob get_default = lambda -> int : 100;

# Lambda with default parameters
glob power = lambda x: int = 2 , y: int = 3 : x ** y;

# Using lambdas
glob numbers = [1, 2, 3, 4, 5];
glob squared = list(map(lambda x: int : x ** 2, numbers));
glob evens = list(filter(lambda x: int : x % 2 == 0, numbers));

# Lambda returning lambda (closure)
glob make_adder = lambda x: int : (lambda y: int : x + y);
glob add_five = make_adder(5);  # add_five(10) returns 15
