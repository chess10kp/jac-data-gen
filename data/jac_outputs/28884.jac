"""Checks if the correct number of arguments were given to a specific command."""
def ArgumentCountException(function: str, args: int, count: int) -> bool {
    name = ArgumentCountException.__name__;
    if args != count {
        print(f'{function} {name}: Incorrect Number of Arguments. Expected {count}, got {args}.');
        return True;
    }
    return False;
}