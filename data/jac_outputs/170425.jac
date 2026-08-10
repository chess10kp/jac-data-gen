"""Small helper function, takes two objects and returns True if they are equal when cast to int.
	This is mainly intended to facilitate checking two strings that may or may not be ints.
	Most importantly, it will return False if either cannot be cast to int."""
def int_equals(a: int | str | float, b: int | str | float) -> bool {
    try {
        return int(a) == int(b);
    } except ValueError {
        return False;
    }
}