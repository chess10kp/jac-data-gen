"""Challenge 2 - Return whether str_1 characters can make str_2"""
def a_scramble(str_1: str, str_2: str) -> bool {
    arr1 = list(str_1.lower());
    arr2 = list(str_2.lower());
    for i in arr2 {
        try {
            arr1.remove(i);
        } except ValueError {
            return False;
        }
    }
    return True;
}