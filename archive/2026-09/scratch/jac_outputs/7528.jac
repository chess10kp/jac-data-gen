"""Integer division with truncation or rounding away.

  If round_away evaluates as True, the quotient is rounded away from
  zero, otherwise the quotient is truncated.

  """
def div_to_int(
    int_numerator: int,
    int_denominator: int,
    round_away: bool = False
) -> int {
    is_numerator_negative = False;
    if int_numerator < 0 {
        int_numerator = -int_numerator;
        is_numerator_negative = True;
    }
    is_denominator_negative = False;
    if int_denominator < 0 {
        int_denominator = -int_denominator;
        is_denominator_negative = True;
    }
    quotient = int_numerator // int_denominator;
    remainder = int_numerator % int_denominator;
    if round_away and remainder > 0 {
        quotient += 1;
    }
    if is_numerator_negative != is_denominator_negative {
        quotient = -quotient;
    }
    return quotient;
}