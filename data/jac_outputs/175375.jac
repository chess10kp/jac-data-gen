"""How many elements is ``pred(elm)`` true for?

With the default predicate, this counts the number of true elements.
"""
def count_true(seq: list[object], pred: callable[[object], object] = lambda (x: object) { x; }) -> int {
    return sum(1 for x in seq if pred(x));
}