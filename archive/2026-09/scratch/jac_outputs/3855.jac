"""Calculates the GC content of DNA sequence x."""
def calculate_gc(x: str) -> float {
    x = x.upper();
    float(x.count('G') + x.count('C')) / (x.count('G') + x.count('C') + x.count('A') + x.count('T'))
}