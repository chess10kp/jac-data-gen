"""Convert decimal number to binary number by iteration.

Time complexity: O(d/2).
Space complexity: O(d/2).
"""
def decimal_to_base2(dec: int) -> str {
    rem_stack: list[int] = [];
    while dec > 0 {
        rem = dec % 2;
        dec = dec // 2;
        rem_stack.append(rem);
    }
    bin_num = '';
    while rem_stack {
        bin_num += str(rem_stack.pop());
    }
    return bin_num;
}