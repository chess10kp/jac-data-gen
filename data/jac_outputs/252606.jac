"""Is this encoding required by the XML 1.0 Specification, 4.3.3?"""
def isStandard(x: str) -> bool {
    return x.upper() in ('UTF-8', 'UTF-16');
}