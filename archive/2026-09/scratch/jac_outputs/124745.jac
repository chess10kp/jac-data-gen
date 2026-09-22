"""Returns puzzle with high or medium complexity."""
def get_puzzle(complex: bool = False) -> str {
    if complex {
        return '4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......';
    }
    return '..3.2.6..9..3.5..1..18.64....81.29..7.......8..67.82....26.95..8..2.3..9..5.1.3..';
}