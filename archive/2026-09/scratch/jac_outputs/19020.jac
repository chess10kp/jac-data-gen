""" Returns None if fiscal_quarter is invalid or not a number. """
def convert_fiscal_quarter_to_fiscal_period(fiscal_quarter: int) -> int | None {
    return {1: 3, 2: 6, 3: 9, 4: 12}.get(fiscal_quarter);
}