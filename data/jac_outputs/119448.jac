"""Combine the spdx ids."""
def mergeSPDX(spdxA: str, spdxB: str) -> str {
    if len(spdxA) == 0 {
        return spdxB;
    }
    if len(spdxB) == 0 {
        return spdxA;
    }
    return spdxA + "+" + spdxB;
}