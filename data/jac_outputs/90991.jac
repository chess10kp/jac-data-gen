"""Subtract two numbers and return the difference"""
def subtract(a: Any, b: Any) -> object {
    difference = round((a - b), 4);
    print(
        (
            "The difference of "
            + str(a)
            + " and "
            + str(b)
            + " is "
            + str(difference)
            + "."
        )
    );
    return (str(a) + " - " + str(b) + " = " + str(difference));
}