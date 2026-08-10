""" Create region string from coordinates.
    takes 2 (1 for human 1-9) digit chromosome,
    begin and end positions (1 indexed)"""
def make_region(chromosome: int | str, begin: int, end: int) -> str {
    return f"chr{chromosome}:{begin}-{end}";
}