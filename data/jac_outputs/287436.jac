"""Checks whether numbers in list are all unique."""
def check_numbers_unique(number_list: list[int]) -> bool {
    number_set = set();
    for number in number_list {
        if number not in number_set {
            if number not in [' ', '*'] {
                number_set.add(number);
            }
        } else {
            return False;
        }
    }
    return True;
}