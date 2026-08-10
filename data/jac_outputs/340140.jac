""" Adds a newline to the value once after every arg characters """
def newline(value: str, arg: int) -> str {
    assert arg > 0;
    new_value = "";
    for i in range(len(value)) {
        new_value += value[i];
        if i % arg == 0 and i != 0 {
            new_value += " ";
        }
    }
    return new_value;
}