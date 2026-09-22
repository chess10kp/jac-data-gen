"""Function to multiply a number by a digit"""
def rec_multiply(a_multiplier: Any, digit: Any, carry: Any) -> object {
    if (a_multiplier == '') {
        return str(carry) if carry else '';
    }
    prefix = a_multiplier[:-1];
    last_digit = int(a_multiplier[-1]);
    this_product = (last_digit * digit) + carry;
    this_result = this_product % 10;
    this_carry = this_product // 10;
    return (rec_multiply(prefix, digit, this_carry) + str(this_result));
}