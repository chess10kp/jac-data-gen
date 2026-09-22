"""
    Improved version, stop when no swap occur
    :type nums: List[int]
    :rtype: List[int]
    """
def bubbleSort2(nums: list[int]) -> list[int] {
    res = list(nums);
    flag = True;
    while flag {
        flag = False;
        for j in range(1, len(res)) {
            if res[j - 1] > res[j] {
                (res[j - 1], res[j]) = (res[j], res[j - 1]);
                flag = True;
            }
        }
    }
    return res;
}