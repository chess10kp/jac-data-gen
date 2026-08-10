"""[1,2..4]+[6] -> [1,2..4,6]"""
def simplify3(string: str) -> str {
    string.replace("]+[", ",")
}