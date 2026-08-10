"""The minimum number of moves to complete a Tower of Hanoi is known as a Mersenne Number."""
def hanoi(disks: int) -> int {
    (2 ** disks) - 1
}