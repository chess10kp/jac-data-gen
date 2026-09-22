""" Set particular bits, used to update particular fields in MSR values"""
def setbits(val: Any, base: Any, length: Any, new: Any) -> object {
    return ((val ^ (val & (((2 ** length) - 1) << base))) + (new << base));
}