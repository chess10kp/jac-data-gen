"""Check that all of the required fields are present as keys in the input dictionary."""
def check_fields_present(passport: dict[str, str], validity_checks: dict[str, str]) -> bool {
    return validity_checks.keys() <= passport.keys();
}