# safe_div.na.jac

def safe_divide(a: int, b: int) -> str {
    try {
        result = a // b;
        return f"{a} / {b} = {result}";
    } except ZeroDivisionError {
        return "Error: division by zero";
    }
}

with entry {
    print(safe_divide(10, 3));
    print(safe_divide(10, 0));
}
