"""
This function takes the preference ranking data as an input parameter. It computes the
head to head winner for the two candidates that are passed into it as parameters.
If the first candidate passed as a paramter wins against the second candidate, then
the function will return true, else, the function will return false.
"""
def isWinner(data: list[list[int | str]], c1: int | str, c2: int | str) -> bool {
    len_c1 = 0;
    len_c2 = 0;
    count_c1 = 0;
    count_c2 = 0;
    for c in data {
        for (i, item) in enumerate(c) {
            if item == c1 {
                len_c1 = i;
            } elif item == c2 {
                len_c2 = i;
            }
        }
        if len_c2 >= len_c1 {
            count_c1 = count_c1 + 1;
        } elif len_c2 <= len_c1 {
            count_c2 = count_c2 + 1;
        }
    }
    return count_c1 >= count_c2;
}