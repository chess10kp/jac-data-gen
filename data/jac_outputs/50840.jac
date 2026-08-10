"""
    :type digits: List[int]
    :rtype: List[int]
    """
def plusOne(digits: Any) -> object {
    digits[-1] = digits[-1] + 1;
    res = [];
    ten = 0;
    i = len(digits) - 1;
    while ((i >= 0) or (ten == 1)) {
        sum = 0;
        if (i >= 0) {
            sum += digits[i];
        }
        if ten {
            sum += 1;
        }
        res.append((sum % 10));
        ten = sum / 10;
        i -= 1;
    }
    return res[::-1];
}