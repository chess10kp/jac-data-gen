"""Guard against value errors when attempting to
       convert a null to int"""
def validate_int(arg: Any) -> object {
    if (len(arg) < 1) {
        return 0;
    }
    return int(arg);
}