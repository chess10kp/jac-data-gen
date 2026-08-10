"""
Two strings are anagrams if they are made of the same letters
arranged differently (ignoring the case).
"""
def check_anagrams(first_str: str, second_str: str) -> bool {
    return "".join(sorted(first_str.lower())).strip() == "".join(sorted(second_str.lower())).strip();
}