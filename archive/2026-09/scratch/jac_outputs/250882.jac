"""Return exclusive OR for boolean arguments"""
def xor(first: bool, second: bool) -> bool {
    first and not second or not first and second
}