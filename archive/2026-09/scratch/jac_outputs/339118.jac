"""Check whether the EC numbers are the same under the used wildcard level."""
def is_fitting_ec_numbers(
    ec_number_one: str, ec_number_two: str, wildcard_level: int
) -> bool {
    if wildcard_level == 0 {
        ec_number_one_full_numbers = ec_number_one.split(".");
        ec_number_two_full_numbers = ec_number_two.split(".");
    } else {
        ec_number_one_full_numbers = ec_number_one.split(".")[:-wildcard_level];
        ec_number_two_full_numbers = ec_number_two.split(".")[:-wildcard_level];
    }
    return ec_number_one_full_numbers == ec_number_two_full_numbers;
}