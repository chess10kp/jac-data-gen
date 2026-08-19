# Wrong - missing type annotations
# def add(a, b) {
#     return a + b;
# }

# Correct
def add(a: int, b: int) -> int {
    return a + b;
}
