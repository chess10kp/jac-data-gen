"""Method that evaluates the ATLEAST gate."""
def atLeastGate(argumentValues: list[int], k: float) -> int {
    return 1 if argumentValues.count(1) >= k else 0;
}