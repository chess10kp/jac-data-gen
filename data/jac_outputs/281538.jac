"""Check that iyr is valid."""
def iyr_valid(passport: dict) -> bool {
    return len(passport['iyr']) == 4 and 2010 <= int(passport['iyr']) <= 2020;
}