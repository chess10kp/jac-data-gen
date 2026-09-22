""" Takes a sorted word list and checks for presence of target word using bisection search"""
def in_bisect(word_list: list[str], target: str) -> bool {
    split_point = len(word_list) // 2;
    if target == word_list[split_point] {
        return True;
    }
    if len(word_list) <= 1 {
        return False;
    }
    if target < word_list[split_point] {
        return in_bisect(word_list[0:split_point], target);
    }
    return in_bisect(word_list[split_point:], target);
}