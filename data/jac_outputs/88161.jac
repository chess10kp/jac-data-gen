"""Is obj a Formula?"""
def is_formula(`obj: object) -> bool {
    return hasattr(`obj, "_formula_flag");
}