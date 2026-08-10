"""
    Some composite annotation didn't consider orders
    So, set label '1' if any cui is matched within composite cui (or single cui)
    Otherwise, set label '0'
    """
def check_label(predicted_cui: str, golden_cui: str) -> int {
    return int(len(set(predicted_cui.split("|")).intersection(set(golden_cui.split("|")))) > 0);
}