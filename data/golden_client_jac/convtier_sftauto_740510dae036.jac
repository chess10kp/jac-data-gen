def checkInteger(num: Any) -> object {
    if (
        isinstance(num, int)
        and not math.isnan(num)
        and (num != float('inf'))
        and (num != float('-inf'))
    ) {
        return True;
    }
    return False;
}



with entry {
    print(checkInteger('hello'));
}
